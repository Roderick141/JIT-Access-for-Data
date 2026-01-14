-- =============================================
-- ETL Procedure: Sync Users from CDC (SCD Type 2)
-- Syncs changes from jit.Users (CDC) to reporting.Users
-- Implements Slowly Changing Dimension Type 2 (historical tracking)
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Sync_Users]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Sync_Users]
GO

CREATE PROCEDURE [reporting].[sp_Reporting_Sync_Users]
    @FullSync BIT = 0  -- If 1, performs full sync (ignores LSN tracking)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CaptureInstance NVARCHAR(128) = 'jit_Users';
    DECLARE @FromLSN BINARY(10);
    DECLARE @ToLSN BINARY(10);
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX);
    DECLARE @LastSyncLSN BINARY(10);

    BEGIN TRY
        -- Get LSN range
        SET @ToLSN = sys.fn_cdc_get_max_lsn();

        IF @FullSync = 1
        BEGIN
            -- Full sync: start from minimum LSN
            SET @FromLSN = sys.fn_cdc_get_min_lsn(@CaptureInstance);
        END
        ELSE
        BEGIN
            -- Incremental sync: get last processed LSN
            SELECT @LastSyncLSN = LastSyncLSN
            FROM [reporting].[CDC_SyncState]
            WHERE TableName = 'Users';

            IF @LastSyncLSN IS NULL
                SET @FromLSN = sys.fn_cdc_get_min_lsn(@CaptureInstance);
            ELSE
                SET @FromLSN = sys.fn_cdc_increment_lsn(@LastSyncLSN);
        END

        -- Check if there are changes to process
        IF @FromLSN IS NULL OR @ToLSN IS NULL OR @FromLSN > @ToLSN
        BEGIN
            EXEC [reporting].[sp_Reporting_Helper_LogETL]
                @TableName = 'Users',
                @Operation = 'Sync',
                @Status = 'Success',
                @RowsProcessed = 0,
                @Details = 'No changes to process';
            RETURN;
        END

        -- Process INSERT (operation = 2) - Create new dimension row
        INSERT INTO [reporting].[Users]
            (UserId, LoginName, GivenName, Surname, DisplayName, Email, Division, Department, 
             JobTitle, SeniorityLevel, IsAdmin, IsApprover, IsDataSteward, IsActive, 
             LastAdSyncUtc, CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy, StartDate, EndDate, IsCurrent)
        SELECT 
            UserId, LoginName, GivenName, Surname, DisplayName, Email, Division, Department,
            JobTitle, SeniorityLevel, IsAdmin, IsApprover, IsDataSteward, IsActive,
            LastAdSyncUtc, CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy,
            UpdatedUtc AS StartDate,  -- Use UpdatedUtc as StartDate (should match CreatedUtc on INSERT)
            NULL AS EndDate,
            1 AS IsCurrent
        FROM cdc.fn_cdc_get_all_changes_jit_Users(@FromLSN, @ToLSN, 'all')
        WHERE __$operation = 2;  -- INSERT

        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        -- Process UPDATE (operation = 4) - SCD Type 2: Close old row, create new row
        -- Step 1: Close old current row (set EndDate and IsCurrent = 0)
        UPDATE r
        SET
            EndDate = s.UpdatedUtc,  -- Set EndDate to the update timestamp
            IsCurrent = 0
        FROM [reporting].[Users] r
        INNER JOIN cdc.fn_cdc_get_all_changes_jit_Users(@FromLSN, @ToLSN, 'all') s
            ON r.UserId = s.UserId AND r.IsCurrent = 1
        WHERE s.__$operation = 4;  -- UPDATE AFTER

        -- Step 2: Insert new current row
        INSERT INTO [reporting].[Users]
            (UserId, LoginName, GivenName, Surname, DisplayName, Email, Division, Department, 
             JobTitle, SeniorityLevel, IsAdmin, IsApprover, IsDataSteward, IsActive, 
             LastAdSyncUtc, CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy, StartDate, EndDate, IsCurrent)
        SELECT 
            UserId, LoginName, GivenName, Surname, DisplayName, Email, Division, Department,
            JobTitle, SeniorityLevel, IsAdmin, IsApprover, IsDataSteward, IsActive,
            LastAdSyncUtc, CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy,
            UpdatedUtc AS StartDate,  -- Use UpdatedUtc as StartDate
            NULL AS EndDate,
            1 AS IsCurrent
        FROM cdc.fn_cdc_get_all_changes_jit_Users(@FromLSN, @ToLSN, 'all')
        WHERE __$operation = 4;  -- UPDATE AFTER

        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        -- Process DELETE (operation = 1) - SCD Type 2: Soft delete (close current row, don't delete)
        -- Note: DELETE change table only contains before image, use GETUTCDATE() as deletion timestamp
        UPDATE r
        SET
            EndDate = GETUTCDATE(),  -- Set EndDate to current timestamp (DELETE change table doesn't have timestamp)
            IsCurrent = 0
        FROM [reporting].[Users] r
        INNER JOIN cdc.fn_cdc_get_all_changes_jit_Users(@FromLSN, @ToLSN, 'all') s
            ON r.UserId = s.UserId AND r.IsCurrent = 1
        WHERE s.__$operation = 1;  -- DELETE

        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        -- Update sync state
        MERGE [reporting].[CDC_SyncState] AS target
        USING (SELECT 'Users' AS TableName, @CaptureInstance AS CaptureInstance, @ToLSN AS LastSyncLSN, GETUTCDATE() AS LastSyncUtc) AS source
        ON target.TableName = source.TableName
        WHEN MATCHED THEN
            UPDATE SET LastSyncLSN = source.LastSyncLSN, LastSyncUtc = source.LastSyncUtc, LastRowCount = @RowsProcessed
        WHEN NOT MATCHED THEN
            INSERT (TableName, CaptureInstance, LastSyncLSN, LastSyncUtc, LastRowCount)
            VALUES (source.TableName, source.CaptureInstance, source.LastSyncLSN, source.LastSyncUtc, @RowsProcessed);

        -- Log success
        EXEC [reporting].[sp_Reporting_Helper_LogETL]
            @TableName = 'Users',
            @Operation = 'Sync',
            @Status = 'Success',
            @RowsProcessed = @RowsProcessed,
            @Details = 'LSN Range: ' + CAST(@FromLSN AS NVARCHAR(50)) + ' to ' + CAST(@ToLSN AS NVARCHAR(50));

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Log error
        EXEC [reporting].[sp_Reporting_Helper_LogETL]
            @TableName = 'Users',
            @Operation = 'Sync',
            @Status = 'Error',
            @ErrorMessage = @ErrorMessage,
            @Details = 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));

        THROW;
    END CATCH
END
GO
