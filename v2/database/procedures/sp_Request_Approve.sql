-- =============================================
-- Stored Procedure: jit.sp_Request_Approve
-- Processes approval decision
-- Creates grants for ALL roles in the request if approved
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Approve]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Approve]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Request_Approve]
    @RequestId BIGINT,
    @ApproverUserId NVARCHAR(255),
    @DecisionComment NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @UserId NVARCHAR(255);
    DECLARE @RequestedDurationMinutes INT;
    DECLARE @GrantId BIGINT;
    DECLARE @CanApprove BIT;
    DECLARE @ApprovalReason NVARCHAR(100);
    DECLARE @CurrentRoleId INT;
    DECLARE @GrantIds NVARCHAR(MAX) = '';
    DECLARE @ApproverUserContextVersionId BIGINT;
    DECLARE @RequesterUserContextVersionId BIGINT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if approver has permission to approve this request (checks ALL roles)
        EXEC [jit].[sp_Approver_CanApproveRequest]
            @ApproverUserId = @ApproverUserId,
            @RequestId = @RequestId,
            @CanApprove = @CanApprove OUTPUT,
            @ApprovalReason = @ApprovalReason OUTPUT;
        
        IF @CanApprove = 0
        BEGIN
            THROW 50005, 'Approver does not have permission to approve this request', 1;
        END
        
        -- Get request details
        SELECT 
            @UserId = UserId,
            @RequesterUserContextVersionId = UserContextVersionId,
            @RequestedDurationMinutes = RequestedDurationMinutes
        FROM [jit].[Requests]
        WHERE RequestId = @RequestId AND Status = 'Pending';
        
        IF @UserId IS NULL
        BEGIN
            THROW 50004, 'Request not found or not pending', 1;
        END

        IF @RequesterUserContextVersionId IS NULL
        BEGIN
            SELECT @RequesterUserContextVersionId = UserContextVersionId
            FROM [jit].[vw_User_CurrentContext]
            WHERE UserId = @UserId;
        END

        IF @RequesterUserContextVersionId IS NULL
        BEGIN
            THROW 50008, 'Requester has no active context version', 1;
        END
        
        -- Record approval
        DECLARE @ApproverLoginName NVARCHAR(255);
        SELECT 
            @ApproverLoginName = LoginName,
            @ApproverUserContextVersionId = UserContextVersionId
        FROM [jit].[vw_User_CurrentContext]
        WHERE UserId = @ApproverUserId;

        IF @ApproverUserContextVersionId IS NULL
        BEGIN
            THROW 50009, 'Approver has no active context version', 1;
        END
        
        IF @ApproverLoginName IS NULL
            SET @ApproverLoginName = @CurrentUser;
        
        INSERT INTO [jit].[Approvals] (
            RequestId, ApproverUserId, ApproverUserContextVersionId, ApproverLoginName, Decision, DecisionComment
        )
        VALUES (
            @RequestId, @ApproverUserId, @ApproverUserContextVersionId, @ApproverLoginName, 'Approved', @DecisionComment
        );
        
        -- Update request status
        UPDATE [jit].[Requests]
        SET Status = 'Approved',
            UpdatedUtc = GETUTCDATE()
        WHERE RequestId = @RequestId;
        
        -- Issue grants for ALL roles in the request
        DECLARE @GrantValidFromUtc DATETIME2 = GETUTCDATE();
        DECLARE @GrantValidToUtc DATETIME2 = DATEADD(MINUTE, @RequestedDurationMinutes, GETUTCDATE());
        
        -- Use LOCAL cursor scope to avoid conflicts with other procedures
        DECLARE role_cursor CURSOR LOCAL STATIC FORWARD_ONLY READ_ONLY FOR 
            SELECT RoleId 
            FROM [jit].[Request_Roles] 
            WHERE RequestId = @RequestId;
        
        OPEN role_cursor;
        FETCH NEXT FROM role_cursor INTO @CurrentRoleId;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC [jit].[sp_Grant_Issue]
                @RequestId = @RequestId,
                @UserId = @UserId,
                @UserContextVersionId = @RequesterUserContextVersionId,
                @RoleId = @CurrentRoleId,
                @ValidFromUtc = @GrantValidFromUtc,
                @ValidToUtc = @GrantValidToUtc,
                @IssuedByUserId = @ApproverUserId,
                @IssuedByUserContextVersionId = @ApproverUserContextVersionId,
                @GrantId = @GrantId OUTPUT;
            
            -- Collect grant IDs for audit log
            IF LEN(@GrantIds) > 0
                SET @GrantIds = @GrantIds + ',';
            SET @GrantIds = @GrantIds + CAST(@GrantId AS NVARCHAR(10));
            
            FETCH NEXT FROM role_cursor INTO @CurrentRoleId;
        END
        
        IF CURSOR_STATUS('local', 'role_cursor') >= 0
        BEGIN
            CLOSE role_cursor;
            DEALLOCATE role_cursor;
        END
        
        -- Log audit
        DECLARE @ApprovedRoleNames NVARCHAR(MAX) = (
            SELECT STRING_AGG(r.RoleName, ', ')
            FROM [jit].[Request_Roles] rr
            INNER JOIN [jit].[Roles] r ON r.RoleId = rr.RoleId AND r.IsActive = 1
            WHERE rr.RequestId = @RequestId
        );
        DECLARE @ApprovedRoleIds NVARCHAR(MAX) = (
            SELECT STRING_AGG(CAST(rr.RoleId AS NVARCHAR(20)), ',')
            FROM [jit].[Request_Roles] rr
            WHERE rr.RequestId = @RequestId
        );
        DECLARE @EscapedDecisionComment NVARCHAR(MAX) = ISNULL(REPLACE(@DecisionComment, '"', '""'), '');
        DECLARE @DetailsJson NVARCHAR(MAX) =
            '{"GrantIds":[' + ISNULL(@GrantIds, '') + '],' +
            '"RoleIds":[' + ISNULL(@ApprovedRoleIds, '') + '],' +
            '"RoleNames":"' + ISNULL(REPLACE(@ApprovedRoleNames, '"', '""'), '') + '",' +
            '"DecisionComment":"' + @EscapedDecisionComment + '"}';
        INSERT INTO [jit].[AuditLog] (
            EventType,
            ActorUserId,
            ActorUserContextVersionId,
            ActorLoginName,
            TargetUserId,
            TargetUserContextVersionId,
            RequestId,
            DetailsJson
        )
        VALUES (
            'Approved',
            @ApproverUserId,
            @ApproverUserContextVersionId,
            @ApproverLoginName,
            @UserId,
            @RequesterUserContextVersionId,
            @RequestId,
            @DetailsJson
        );
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        -- Clean up cursor if it exists
        IF CURSOR_STATUS('local', 'role_cursor') >= 0
        BEGIN
            IF CURSOR_STATUS('local', 'role_cursor') > -1
                CLOSE role_cursor;
            DEALLOCATE role_cursor;
        END
        
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

