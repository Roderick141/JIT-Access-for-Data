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
    @ApproverUserId INT,
    @DecisionComment NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @UserId INT;
    DECLARE @ApproverLoginName NVARCHAR(255);
    DECLARE @CanApprove BIT;
    DECLARE @ApprovalReason NVARCHAR(100);
    
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
        SELECT @UserId = UserId
        FROM [jit].[Requests]
        WHERE RequestId = @RequestId AND Status = 'Pending';
        
        IF @UserId IS NULL
        BEGIN
            THROW 50004, 'Request not found or not pending', 1;
        END
        
        -- Get approver login name
        SELECT @ApproverLoginName = LoginName
        FROM [jit].[Users]
        WHERE UserId = @ApproverUserId;
        
        IF @ApproverLoginName IS NULL
            SET @ApproverLoginName = @CurrentUser;
        
        -- Record denial
        INSERT INTO [jit].[Approvals] (
            RequestId, ApproverUserId, ApproverLoginName, Decision, DecisionComment
        )
        VALUES (
            @RequestId, @ApproverUserId, @ApproverLoginName, 'Denied', @DecisionComment
        );
        
        -- Update request status
        UPDATE [jit].[Requests]
        SET Status = 'Denied',
            UpdatedUtc = GETUTCDATE()
        WHERE RequestId = @RequestId;
        
        -- Log audit
        INSERT INTO [jit].[AuditLog] (EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, DetailsJson)
        VALUES ('Denied', @ApproverUserId, @ApproverLoginName, @UserId, @RequestId, '{}');
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

PRINT 'Stored Procedure [jit].[sp_Request_Deny] created successfully'
GO

