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
    @ApproverUserId INT,
    @DecisionComment NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @UserId INT;
    DECLARE @RequestedDurationMinutes INT;
    DECLARE @GrantId BIGINT;
    DECLARE @CanApprove BIT;
    DECLARE @ApprovalReason NVARCHAR(100);
    DECLARE @CurrentRoleId INT;
    DECLARE @GrantIds NVARCHAR(MAX) = '';
    
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
            @RequestedDurationMinutes = RequestedDurationMinutes
        FROM [jit].[Requests]
        WHERE RequestId = @RequestId AND Status = 'Pending';
        
        IF @UserId IS NULL
        BEGIN
            THROW 50004, 'Request not found or not pending', 1;
        END
        
        -- Record approval
        DECLARE @ApproverLoginName NVARCHAR(255);
        SELECT @ApproverLoginName = LoginName
        FROM [jit].[Users]
        WHERE UserId = @ApproverUserId;
        
        IF @ApproverLoginName IS NULL
            SET @ApproverLoginName = @CurrentUser;
        
        INSERT INTO [jit].[Approvals] (
            RequestId, ApproverUserId, ApproverLoginName, Decision, DecisionComment
        )
        VALUES (
            @RequestId, @ApproverUserId, @ApproverLoginName, 'Approved', @DecisionComment
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
                @RoleId = @CurrentRoleId,
                @ValidFromUtc = @GrantValidFromUtc,
                @ValidToUtc = @GrantValidToUtc,
                @IssuedByUserId = @ApproverUserId,
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
        DECLARE @DetailsJson NVARCHAR(MAX) = '{"GrantIds":[' + @GrantIds + ']}';
        INSERT INTO [jit].[AuditLog] (EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, DetailsJson)
        VALUES ('Approved', @ApproverUserId, @ApproverLoginName, @UserId, @RequestId, @DetailsJson);
        
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

PRINT 'Stored Procedure [jit].[sp_Request_Approve] created successfully'
GO
