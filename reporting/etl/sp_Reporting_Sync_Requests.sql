-- =============================================
-- ETL Procedure: Sync Requests from CDC
-- Includes dimension key resolution (UserDimensionKey)
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Sync_Requests]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Sync_Requests]
GO

CREATE PROCEDURE [reporting].[sp_Reporting_Sync_Requests]
    @FullSync BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CaptureInstance NVARCHAR(128) = 'jit_Requests';
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
            SELECT @LastSyncLSN = LastSyncLSN FROM [reporting].[CDC_SyncState] WHERE TableName = 'Requests';
            SET @FromLSN = CASE WHEN @LastSyncLSN IS NULL THEN sys.fn_cdc_get_min_lsn(@CaptureInstance) ELSE sys.fn_cdc_increment_lsn(@LastSyncLSN) END;
        END
        IF @FromLSN IS NULL OR @ToLSN IS NULL OR @FromLSN > @ToLSN
        BEGIN
            EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Requests', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = 0;
            RETURN;
        END

        -- INSERT with dimension key resolution
        INSERT INTO [reporting].[Requests] (RequestId, UserId, UserDimensionKey, RequestedDurationMinutes, Justification, TicketRef, Status, UserDeptSnapshot, UserTitleSnapshot, CreatedUtc, UpdatedUtc, CreatedBy)
        SELECT 
            s.RequestId, 
            s.UserId,
            u.UserDimensionKey,  -- Resolve dimension key at request creation time
            s.RequestedDurationMinutes, 
            s.Justification, 
            s.TicketRef, 
            s.Status, 
            s.UserDeptSnapshot, 
            s.UserTitleSnapshot, 
            s.CreatedUtc, 
            s.UpdatedUtc, 
            s.CreatedBy
        FROM cdc.fn_cdc_get_all_changes_jit_Requests(@FromLSN, @ToLSN, 'all') s
        LEFT JOIN [reporting].[Users] u 
            ON s.UserId = u.UserId 
            AND s.CreatedUtc >= u.StartDate 
            AND (s.CreatedUtc < u.EndDate OR u.EndDate IS NULL)
        WHERE s.__$operation = 2;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        -- UPDATE (update dimension key if user changed, though unlikely for Requests)
        UPDATE r 
        SET 
            UserId = s.UserId,
            UserDimensionKey = u.UserDimensionKey,  -- Re-resolve dimension key
            RequestedDurationMinutes = s.RequestedDurationMinutes, 
            Justification = s.Justification, 
            TicketRef = s.TicketRef, 
            Status = s.Status, 
            UserDeptSnapshot = s.UserDeptSnapshot, 
            UserTitleSnapshot = s.UserTitleSnapshot, 
            CreatedUtc = s.CreatedUtc, 
            UpdatedUtc = s.UpdatedUtc, 
            CreatedBy = s.CreatedBy
        FROM [reporting].[Requests] r 
        INNER JOIN cdc.fn_cdc_get_all_changes_jit_Requests(@FromLSN, @ToLSN, 'all') s ON r.RequestId = s.RequestId 
        LEFT JOIN [reporting].[Users] u 
            ON s.UserId = u.UserId 
            AND s.UpdatedUtc >= u.StartDate 
            AND (s.UpdatedUtc < u.EndDate OR u.EndDate IS NULL)
        WHERE s.__$operation = 4;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        DELETE r FROM [reporting].[Requests] r INNER JOIN cdc.fn_cdc_get_all_changes_jit_Requests(@FromLSN, @ToLSN, 'all') s ON r.RequestId = s.RequestId WHERE s.__$operation = 1;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        MERGE [reporting].[CDC_SyncState] AS target USING (SELECT 'Requests' AS TableName, @CaptureInstance AS CaptureInstance, @ToLSN AS LastSyncLSN, GETUTCDATE() AS LastSyncUtc, @RowsProcessed AS LastRowCount) AS source ON target.TableName = source.TableName
        WHEN MATCHED THEN UPDATE SET LastSyncLSN = source.LastSyncLSN, LastSyncUtc = source.LastSyncUtc, LastRowCount = source.LastRowCount
        WHEN NOT MATCHED THEN INSERT (TableName, CaptureInstance, LastSyncLSN, LastSyncUtc, LastRowCount) VALUES (source.TableName, source.CaptureInstance, source.LastSyncLSN, source.LastSyncUtc, source.LastRowCount);

        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Requests', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = @RowsProcessed;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Requests', @Operation = 'Sync', @Status = 'Error', @ErrorMessage = @ErrorMessage;
        THROW;
    END CATCH
END
GO
