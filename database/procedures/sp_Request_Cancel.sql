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
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @CurrentStatus NVARCHAR(50);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check request belongs to user and is cancellable
        SELECT @CurrentStatus = Status
        FROM [jit].[Requests]
        WHERE RequestId = @RequestId AND UserId = @UserId;
        
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
        INSERT INTO [jit].[AuditLog] (EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, DetailsJson)
        VALUES ('RequestCancelled', @UserId, @CurrentUser, @UserId, @RequestId, '{}');
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

