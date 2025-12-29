-- =============================================
-- Stored Procedure: jit.sp_Request_Approve
-- Processes approval decision
-- Creates grant if approved
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Approve]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Approve]
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
    DECLARE @RoleId INT;
    DECLARE @RequestedDurationMinutes INT;
    DECLARE @GrantId BIGINT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get request details
        SELECT 
            @UserId = UserId,
            @RoleId = RoleId,
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
        
        -- Issue grant
        EXEC [jit].[sp_Grant_Issue]
            @RequestId = @RequestId,
            @UserId = @UserId,
            @RoleId = @RoleId,
            @ValidFromUtc = GETUTCDATE(),
            @ValidToUtc = DATEADD(MINUTE, @RequestedDurationMinutes, GETUTCDATE()),
            @IssuedByUserId = @ApproverUserId,
            @GrantId = @GrantId OUTPUT;
        
        -- Log audit
        INSERT INTO [jit].[AuditLog] (EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, DetailsJson)
        VALUES ('Approved', @ApproverUserId, @ApproverLoginName, @UserId, @RequestId,
            '{"GrantId":' + CAST(@GrantId AS NVARCHAR(10)) + '}');
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

PRINT 'Stored Procedure [jit].[sp_Request_Approve] created successfully'
GO

