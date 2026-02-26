-- =============================================
-- Stored Procedure: jit.sp_Request_Deny
-- Processes denial decision
-- Updates request status
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Deny]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Deny]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Request_Deny]
    @RequestId BIGINT,
    @ApproverUserId NVARCHAR(255),
    @DecisionComment NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @UserId NVARCHAR(255);
    DECLARE @ApproverLoginName NVARCHAR(255);
    DECLARE @CanApprove BIT;
    DECLARE @ApprovalReason NVARCHAR(100);
    DECLARE @ApproverUserContextVersionId BIGINT;
    DECLARE @RequesterUserContextVersionId BIGINT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if approver has permission to deny this request (same as approve)
        EXEC [jit].[sp_Approver_CanApproveRequest]
            @ApproverUserId = @ApproverUserId,
            @RequestId = @RequestId,
            @CanApprove = @CanApprove OUTPUT,
            @ApprovalReason = @ApprovalReason OUTPUT;
        
        IF @CanApprove = 0
        BEGIN
            THROW 50005, 'Approver does not have permission to deny this request', 1;
        END
        
        -- Get request details
        SELECT 
            @UserId = UserId,
            @RequesterUserContextVersionId = UserContextVersionId
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
        
        -- Get approver login name
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
        
        -- Record denial
        INSERT INTO [jit].[Approvals] (
            RequestId, ApproverUserId, ApproverUserContextVersionId, ApproverLoginName, Decision, DecisionComment
        )
        VALUES (
            @RequestId, @ApproverUserId, @ApproverUserContextVersionId, @ApproverLoginName, 'Denied', @DecisionComment
        );
        
        -- Update request status
        UPDATE [jit].[Requests]
        SET Status = 'Denied',
            UpdatedUtc = GETUTCDATE()
        WHERE RequestId = @RequestId;
        
        -- Log audit
        DECLARE @DeniedRoleNames NVARCHAR(MAX) = (
            SELECT STRING_AGG(r.RoleName, ', ')
            FROM [jit].[Request_Roles] rr
            INNER JOIN [jit].[Roles] r ON r.RoleId = rr.RoleId AND r.IsActive = 1
            WHERE rr.RequestId = @RequestId
        );
        DECLARE @DeniedRoleIds NVARCHAR(MAX) = (
            SELECT STRING_AGG(CAST(rr.RoleId AS NVARCHAR(20)), ',')
            FROM [jit].[Request_Roles] rr
            WHERE rr.RequestId = @RequestId
        );
        DECLARE @EscapedDenyComment NVARCHAR(MAX) = ISNULL(REPLACE(@DecisionComment, '"', '""'), '');
        DECLARE @DenyDetailsJson NVARCHAR(MAX) =
            '{"RoleIds":[' + ISNULL(@DeniedRoleIds, '') + '],' +
            '"RoleNames":"' + ISNULL(REPLACE(@DeniedRoleNames, '"', '""'), '') + '",' +
            '"DecisionComment":"' + @EscapedDenyComment + '"}';
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
            'Denied',
            @ApproverUserId,
            @ApproverUserContextVersionId,
            @ApproverLoginName,
            @UserId,
            @RequesterUserContextVersionId,
            @RequestId,
            @DenyDetailsJson
        );
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

