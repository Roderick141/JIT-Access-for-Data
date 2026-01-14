-- =============================================
-- ETL Procedure: Sync Grants from CDC
-- Includes dimension key resolution (UserDimensionKey, RoleDimensionKey)
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Sync_Grants]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Sync_Grants]
GO

CREATE PROCEDURE [reporting].[sp_Reporting_Sync_Grants]
    @FullSync BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CaptureInstance NVARCHAR(128) = 'jit_Grants';
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
            SELECT @LastSyncLSN = LastSyncLSN FROM [reporting].[CDC_SyncState] WHERE TableName = 'Grants';
            SET @FromLSN = CASE WHEN @LastSyncLSN IS NULL THEN sys.fn_cdc_get_min_lsn(@CaptureInstance) ELSE sys.fn_cdc_increment_lsn(@LastSyncLSN) END;
        END
        IF @FromLSN IS NULL OR @ToLSN IS NULL OR @FromLSN > @ToLSN
        BEGIN
            EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Grants', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = 0;
            RETURN;
        END

        INSERT INTO [reporting].[Grants] (GrantId, RequestId, UserId, UserDimensionKey, RoleId, RoleDimensionKey, ValidFromUtc, ValidToUtc, RevokedUtc, RevokeReason, IssuedByUserId, Status)
        SELECT s.GrantId, s.RequestId, s.UserId, u.UserDimensionKey, s.RoleId, r.RoleDimensionKey, s.ValidFromUtc, s.ValidToUtc, s.RevokedUtc, s.RevokeReason, s.IssuedByUserId, s.Status
        FROM cdc.fn_cdc_get_all_changes_jit_Grants(@FromLSN, @ToLSN, 'all') s
        LEFT JOIN [reporting].[Users] u ON s.UserId = u.UserId AND s.ValidFromUtc >= u.StartDate AND (s.ValidFromUtc < u.EndDate OR u.EndDate IS NULL)
        LEFT JOIN [reporting].[Roles] r ON s.RoleId = r.RoleId AND s.ValidFromUtc >= r.StartDate AND (s.ValidFromUtc < r.EndDate OR r.EndDate IS NULL)
        WHERE s.__$operation = 2;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        UPDATE r SET RequestId = s.RequestId, UserId = s.UserId, UserDimensionKey = u.UserDimensionKey, RoleId = s.RoleId, RoleDimensionKey = r2.RoleDimensionKey, ValidFromUtc = s.ValidFromUtc, ValidToUtc = s.ValidToUtc, RevokedUtc = s.RevokedUtc, RevokeReason = s.RevokeReason, IssuedByUserId = s.IssuedByUserId, Status = s.Status
        FROM [reporting].[Grants] r INNER JOIN cdc.fn_cdc_get_all_changes_jit_Grants(@FromLSN, @ToLSN, 'all') s ON r.GrantId = s.GrantId 
        LEFT JOIN [reporting].[Users] u ON s.UserId = u.UserId AND s.ValidFromUtc >= u.StartDate AND (s.ValidFromUtc < u.EndDate OR u.EndDate IS NULL)
        LEFT JOIN [reporting].[Roles] r2 ON s.RoleId = r2.RoleId AND s.ValidFromUtc >= r2.StartDate AND (s.ValidFromUtc < r2.EndDate OR r2.EndDate IS NULL)
        WHERE s.__$operation = 4;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        DELETE r FROM [reporting].[Grants] r INNER JOIN cdc.fn_cdc_get_all_changes_jit_Grants(@FromLSN, @ToLSN, 'all') s ON r.GrantId = s.GrantId WHERE s.__$operation = 1;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        MERGE [reporting].[CDC_SyncState] AS target USING (SELECT 'Grants' AS TableName, @CaptureInstance AS CaptureInstance, @ToLSN AS LastSyncLSN, GETUTCDATE() AS LastSyncUtc, @RowsProcessed AS LastRowCount) AS source ON target.TableName = source.TableName
        WHEN MATCHED THEN UPDATE SET LastSyncLSN = source.LastSyncLSN, LastSyncUtc = source.LastSyncUtc, LastRowCount = source.LastRowCount
        WHEN NOT MATCHED THEN INSERT (TableName, CaptureInstance, LastSyncLSN, LastSyncUtc, LastRowCount) VALUES (source.TableName, source.CaptureInstance, source.LastSyncLSN, source.LastSyncUtc, source.LastRowCount);

        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Grants', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = @RowsProcessed;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Grants', @Operation = 'Sync', @Status = 'Error', @ErrorMessage = @ErrorMessage;
        THROW;
    END CATCH
END
GO
