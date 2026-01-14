-- =============================================
-- ETL Procedure: Sync Approvals from CDC
-- Includes dimension key resolution (ApproverUserDimensionKey)
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Sync_Approvals]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Sync_Approvals]
GO

CREATE PROCEDURE [reporting].[sp_Reporting_Sync_Approvals]
    @FullSync BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CaptureInstance NVARCHAR(128) = 'jit_Approvals';
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
            SELECT @LastSyncLSN = LastSyncLSN FROM [reporting].[CDC_SyncState] WHERE TableName = 'Approvals';
            SET @FromLSN = CASE WHEN @LastSyncLSN IS NULL THEN sys.fn_cdc_get_min_lsn(@CaptureInstance) ELSE sys.fn_cdc_increment_lsn(@LastSyncLSN) END;
        END
        IF @FromLSN IS NULL OR @ToLSN IS NULL OR @FromLSN > @ToLSN
        BEGIN
            EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Approvals', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = 0;
            RETURN;
        END

        INSERT INTO [reporting].[Approvals] (ApprovalId, RequestId, ApproverUserId, ApproverUserDimensionKey, ApproverLoginName, Decision, DecisionComment, DecisionUtc)
        SELECT s.ApprovalId, s.RequestId, s.ApproverUserId, u.UserDimensionKey, s.ApproverLoginName, s.Decision, s.DecisionComment, s.DecisionUtc
        FROM cdc.fn_cdc_get_all_changes_jit_Approvals(@FromLSN, @ToLSN, 'all') s
        LEFT JOIN [reporting].[Users] u ON s.ApproverUserId = u.UserId AND s.DecisionUtc >= u.StartDate AND (s.DecisionUtc < u.EndDate OR u.EndDate IS NULL)
        WHERE s.__$operation = 2;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        UPDATE r SET RequestId = s.RequestId, ApproverUserId = s.ApproverUserId, ApproverUserDimensionKey = u.UserDimensionKey, ApproverLoginName = s.ApproverLoginName, Decision = s.Decision, DecisionComment = s.DecisionComment, DecisionUtc = s.DecisionUtc
        FROM [reporting].[Approvals] r INNER JOIN cdc.fn_cdc_get_all_changes_jit_Approvals(@FromLSN, @ToLSN, 'all') s ON r.ApprovalId = s.ApprovalId 
        LEFT JOIN [reporting].[Users] u ON s.ApproverUserId = u.UserId AND s.DecisionUtc >= u.StartDate AND (s.DecisionUtc < u.EndDate OR u.EndDate IS NULL)
        WHERE s.__$operation = 4;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        DELETE r FROM [reporting].[Approvals] r INNER JOIN cdc.fn_cdc_get_all_changes_jit_Approvals(@FromLSN, @ToLSN, 'all') s ON r.ApprovalId = s.ApprovalId WHERE s.__$operation = 1;
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;

        MERGE [reporting].[CDC_SyncState] AS target USING (SELECT 'Approvals' AS TableName, @CaptureInstance AS CaptureInstance, @ToLSN AS LastSyncLSN, GETUTCDATE() AS LastSyncUtc, @RowsProcessed AS LastRowCount) AS source ON target.TableName = source.TableName
        WHEN MATCHED THEN UPDATE SET LastSyncLSN = source.LastSyncLSN, LastSyncUtc = source.LastSyncUtc, LastRowCount = source.LastRowCount
        WHEN NOT MATCHED THEN INSERT (TableName, CaptureInstance, LastSyncLSN, LastSyncUtc, LastRowCount) VALUES (source.TableName, source.CaptureInstance, source.LastSyncLSN, source.LastSyncUtc, source.LastRowCount);

        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Approvals', @Operation = 'Sync', @Status = 'Success', @RowsProcessed = @RowsProcessed;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        EXEC [reporting].[sp_Reporting_Helper_LogETL] @TableName = 'Approvals', @Operation = 'Sync', @Status = 'Error', @ErrorMessage = @ErrorMessage;
        THROW;
    END CATCH
END
GO
