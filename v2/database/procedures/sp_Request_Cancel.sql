-- =============================================
-- Stored Procedure: jit.sp_Request_Cancel
-- Allows requester to cancel pending requests
-- Updates status
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Cancel]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Cancel]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Request_Cancel]
    @RequestId BIGINT,
    @UserId NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @CurrentStatus NVARCHAR(50);
    DECLARE @RequesterUserContextVersionId BIGINT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check request belongs to user and is cancellable
        SELECT 
            @CurrentStatus = Status,
            @RequesterUserContextVersionId = UserContextVersionId
        FROM [jit].[Requests]
        WHERE RequestId = @RequestId AND UserId = @UserId;

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
        
        IF @CurrentStatus IS NULL
        BEGIN
            THROW 50005, 'Request not found or does not belong to user', 1;
        END
        
        IF @CurrentStatus != 'Pending'
        BEGIN
            THROW 50006, 'Only pending requests can be cancelled', 1;
        END
        
        -- Update status
        UPDATE [jit].[Requests]
        SET Status = 'Cancelled',
            UpdatedUtc = GETUTCDATE()
        WHERE RequestId = @RequestId;
        
        -- Log audit
        DECLARE @CancelledRoleNames NVARCHAR(MAX) = (
            SELECT STRING_AGG(r.RoleName, ', ')
            FROM [jit].[Request_Roles] rr
            INNER JOIN [jit].[Roles] r ON r.RoleId = rr.RoleId AND r.IsActive = 1
            WHERE rr.RequestId = @RequestId
        );
        DECLARE @CancelledRoleIds NVARCHAR(MAX) = (
            SELECT STRING_AGG(CAST(rr.RoleId AS NVARCHAR(20)), ',')
            FROM [jit].[Request_Roles] rr
            WHERE rr.RequestId = @RequestId
        );
        DECLARE @CancelDetailsJson NVARCHAR(MAX) =
            '{"RoleIds":[' + ISNULL(@CancelledRoleIds, '') + '],' +
            '"RoleNames":"' + ISNULL(REPLACE(@CancelledRoleNames, '"', '""'), '') + '"}';
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
            'RequestCancelled',
            @UserId,
            @RequesterUserContextVersionId,
            @CurrentUser,
            @UserId,
            @RequesterUserContextVersionId,
            @RequestId,
            @CancelDetailsJson
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

