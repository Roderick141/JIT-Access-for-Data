-- =============================================
-- ETL Procedure: Sync AuditLog (Copy-based, not CDC)
-- AuditLog is copied directly since it's append-only
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Sync_AuditLog]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Sync_AuditLog]
GO

CREATE PROCEDURE [reporting].[sp_Reporting_Sync_AuditLog]
    @FullSync BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX);
    DECLARE @LastAuditId BIGINT;

    BEGIN TRY
        -- Get last synced AuditId
        IF @FullSync = 1
            SET @LastAuditId = 0;
        ELSE
            SELECT @LastAuditId = ISNULL(MAX(AuditId), 0) FROM [reporting].[AuditLog];

        -- Insert new records (append-only, so just INSERT new records)
        INSERT INTO [reporting].[AuditLog]
            (AuditId, EventUtc, EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, GrantId, DetailsJson)
        SELECT 
            AuditId, EventUtc, EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, GrantId, DetailsJson
        FROM [DMAP_JIT_Permissions].[jit].[AuditLog]
        WHERE AuditId > @LastAuditId;

        SET @RowsProcessed = @@ROWCOUNT;

        EXEC [reporting].[sp_Reporting_Helper_LogETL] 
            @TableName = 'AuditLog', 
            @Operation = 'Sync', 
            @Status = 'Success', 
            @RowsProcessed = @RowsProcessed,
            @Details = 'Last AuditId: ' + CAST(@LastAuditId AS NVARCHAR(20));

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        EXEC [reporting].[sp_Reporting_Helper_LogETL] 
            @TableName = 'AuditLog', 
            @Operation = 'Sync', 
            @Status = 'Error', 
            @ErrorMessage = @ErrorMessage;
        THROW;
    END CATCH
END
GO
