-- =============================================
-- ETL Procedure: Sync Request_Roles from CDC
-- Includes dimension key resolution (RoleDimensionKey)
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Sync_Request_Roles]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Sync_Request_Roles]
GO

CREATE PROCEDURE [reporting].[sp_Reporting_Sync_Request_Roles]
    @FullSync BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CaptureInstance NVARCHAR(128) = 'jit_Request_Roles';
    DECLARE @FromLSN BINARY(10);
    DECLARE @ToLSN BINARY(10);
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX);
    DECLARE @LastSyncLSN BINARY(10);

    BEGIN TRY
        SET @ToLSN = sys.fn_cdc_get_max_lsn();
        IF @FullSync = 1
            SET @FromLSN = sys.fn_cdc_get_min_lsn(@CaptureInstance);
        ELSE
        BEGIN
            SELECT @LastSyncLSN = LastSyncLSN FROM [reporting].[CDC_SyncState] WHERE TableName = 'Request_Roles';
            SET @FromLSN = CASE WHEN @LastSyncLSN IS NULL THEN sys.fn_cdc_get_min_lsn(@CaptureInstance) ELSE sys.fn_cdc_increment_lsn(@LastSyncLSN) END;
        END
        IF @FromLSN IS NULL OR @ToLSN IS NULL OR @FromLSN > @ToLSN
        BEGIN
            EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Request_Roles', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = 0;
            RETURN;
        END

        INSERT INTO [reporting].[Request_Roles] (RequestId, RoleId, RoleDimensionKey, CreatedUtc)
        SELECT s.RequestId, s.RoleId, r.RoleDimensionKey, s.CreatedUtc
        FROM cdc.fn_cdc_get_all_changes_jit_Request_Roles(@FromLSN, @ToLSN, 'all') s
        LEFT JOIN [reporting].[Roles] r ON s.RoleId = r.RoleId AND s.CreatedUtc >= r.StartDate AND (s.CreatedUtc < r.EndDate OR r.EndDate IS NULL)
        WHERE s.__$operation = 2;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        UPDATE r SET CreatedUtc = s.CreatedUtc, RoleDimensionKey = r2.RoleDimensionKey
        FROM [reporting].[Request_Roles] r INNER JOIN cdc.fn_cdc_get_all_changes_jit_Request_Roles(@FromLSN, @ToLSN, 'all') s ON r.RequestId = s.RequestId AND r.RoleId = s.RoleId 
        LEFT JOIN [reporting].[Roles] r2 ON s.RoleId = r2.RoleId AND s.CreatedUtc >= r2.StartDate AND (s.CreatedUtc < r2.EndDate OR r2.EndDate IS NULL)
        WHERE s.__$operation = 4;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        DELETE r FROM [reporting].[Request_Roles] r INNER JOIN cdc.fn_cdc_get_all_changes_jit_Request_Roles(@FromLSN, @ToLSN, 'all') s ON r.RequestId = s.RequestId AND r.RoleId = s.RoleId WHERE s.__$operation = 1;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        MERGE [reporting].[CDC_SyncState] AS target USING (SELECT 'Request_Roles' AS TableName, @CaptureInstance AS CaptureInstance, @ToLSN AS LastSyncLSN, GETUTCDATE() AS LastSyncUtc, @RowsProcessed AS LastRowCount) AS source ON target.TableName = source.TableName
        WHEN MATCHED THEN UPDATE SET LastSyncLSN = source.LastSyncLSN, LastSyncUtc = source.LastSyncUtc, LastRowCount = source.LastRowCount
        WHEN NOT MATCHED THEN INSERT (TableName, CaptureInstance, LastSyncLSN, LastSyncUtc, LastRowCount) VALUES (source.TableName, source.CaptureInstance, source.LastSyncLSN, source.LastSyncUtc, source.LastRowCount);

        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Request_Roles', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = @RowsProcessed;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Request_Roles', @Operation = 'Sync', @Status = 'Error', @ErrorMessage = @ErrorMessage;
        THROW;
    END CATCH
END
GO
