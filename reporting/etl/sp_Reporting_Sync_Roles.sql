-- =============================================
-- ETL Procedure: Sync Roles from CDC (SCD Type 2)
-- Syncs changes from jit.Roles (CDC) to reporting.Roles
-- Implements Slowly Changing Dimension Type 2 (historical tracking)
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Sync_Roles]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Sync_Roles]
GO

CREATE PROCEDURE [reporting].[sp_Reporting_Sync_Roles]
    @FullSync BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CaptureInstance NVARCHAR(128) = 'jit_Roles';
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
            SELECT @LastSyncLSN = LastSyncLSN FROM [reporting].[CDC_SyncState] WHERE TableName = 'Roles';
            SET @FromLSN = CASE WHEN @LastSyncLSN IS NULL THEN sys.fn_cdc_get_min_lsn(@CaptureInstance) ELSE sys.fn_cdc_increment_lsn(@LastSyncLSN) END;
        END
        IF @FromLSN IS NULL OR @ToLSN IS NULL OR @FromLSN > @ToLSN
        BEGIN
            EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Roles', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = 0;
            RETURN;
        END

        -- INSERT
        INSERT INTO [reporting].[Roles] (RoleId, RoleName, Description, MaxDurationMinutes, RequiresTicket, TicketRegex, RequiresJustification, RequiresApproval, AutoApproveMinSeniority, IsEnabled, CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy, StartDate, EndDate, IsCurrent)
        SELECT RoleId, RoleName, Description, MaxDurationMinutes, RequiresTicket, TicketRegex, RequiresJustification, RequiresApproval, AutoApproveMinSeniority, IsEnabled, CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy, UpdatedUtc AS StartDate, NULL AS EndDate, 1 AS IsCurrent
        FROM cdc.fn_cdc_get_all_changes_jit_Roles(@FromLSN, @ToLSN, 'all') WHERE __$operation = 2;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        -- UPDATE: Close old row
        UPDATE r SET EndDate = s.UpdatedUtc, IsCurrent = 0
        FROM [reporting].[Roles] r INNER JOIN cdc.fn_cdc_get_all_changes_jit_Roles(@FromLSN, @ToLSN, 'all') s ON r.RoleId = s.RoleId AND r.IsCurrent = 1 WHERE s.__$operation = 4;

        -- UPDATE: Insert new row
        INSERT INTO [reporting].[Roles] (RoleId, RoleName, Description, MaxDurationMinutes, RequiresTicket, TicketRegex, RequiresJustification, RequiresApproval, AutoApproveMinSeniority, IsEnabled, CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy, StartDate, EndDate, IsCurrent)
        SELECT RoleId, RoleName, Description, MaxDurationMinutes, RequiresTicket, TicketRegex, RequiresJustification, RequiresApproval, AutoApproveMinSeniority, IsEnabled, CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy, UpdatedUtc AS StartDate, NULL AS EndDate, 1 AS IsCurrent
        FROM cdc.fn_cdc_get_all_changes_jit_Roles(@FromLSN, @ToLSN, 'all') WHERE __$operation = 4;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        -- DELETE: Soft delete (close current row)
        UPDATE r SET EndDate = GETUTCDATE(), IsCurrent = 0
        FROM [reporting].[Roles] r INNER JOIN cdc.fn_cdc_get_all_changes_jit_Roles(@FromLSN, @ToLSN, 'all') s ON r.RoleId = s.RoleId AND r.IsCurrent = 1 WHERE s.__$operation = 1;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        MERGE [reporting].[CDC_SyncState] AS target USING (SELECT 'Roles' AS TableName, @CaptureInstance AS CaptureInstance, @ToLSN AS LastSyncLSN, GETUTCDATE() AS LastSyncUtc, @RowsProcessed AS LastRowCount) AS source ON target.TableName = source.TableName
        WHEN MATCHED THEN UPDATE SET LastSyncLSN = source.LastSyncLSN, LastSyncUtc = source.LastSyncUtc, LastRowCount = source.LastRowCount
        WHEN NOT MATCHED THEN INSERT (TableName, CaptureInstance, LastSyncLSN, LastSyncUtc, LastRowCount) VALUES (source.TableName, source.CaptureInstance, source.LastSyncLSN, source.LastSyncUtc, source.LastRowCount);

        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Roles', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = @RowsProcessed;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Roles', @Operation = 'Sync', @Status = 'Error', @ErrorMessage = @ErrorMessage;
        THROW;
    END CATCH
END
GO
