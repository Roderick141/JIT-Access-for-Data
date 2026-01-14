-- =============================================
-- Archive Procedure: Move Old Data from Operational to Reporting
-- Archives data older than retention period (default 90 days)
-- Only archives if data exists in reporting DB
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Create reporting schema in operational DB if it doesn't exist (for this procedure)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'reporting')
BEGIN
    EXEC('CREATE SCHEMA [reporting]')
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Archive_OldData]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Archive_OldData]
GO

-- Note: This procedure runs in the operational database
-- It accesses both operational DB (jit schema) and reporting DB (reporting schema)

CREATE PROCEDURE [reporting].[sp_Reporting_Archive_OldData]
    @RetentionDays INT = 90,  -- Days to keep in operational DB
    @DryRun BIT = 0  -- If 1, only reports what would be archived without deleting
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CutoffDate DATETIME2(7) = DATEADD(DAY, -@RetentionDays, GETUTCDATE());
    DECLARE @RowsArchived INT = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX);
    DECLARE @RequestsCount INT;
    DECLARE @GrantsCount INT;
    DECLARE @ApprovalsCount INT;
    DECLARE @AuditLogCount INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Archive Requests (older than cutoff date)
        SELECT @RequestsCount = COUNT(*)
        FROM [jit].[Requests]
        WHERE CreatedUtc < @CutoffDate;

        IF @DryRun = 0 AND @RequestsCount > 0
        BEGIN
            -- Verify data exists in reporting DB
            IF EXISTS (
                SELECT 1 
                FROM [jit].[Requests] r
                WHERE r.CreatedUtc < @CutoffDate
                AND NOT EXISTS (
                    SELECT 1 FROM [DMAP_JIT_Permissions_Reporting].[reporting].[Requests] rep
                    WHERE rep.RequestId = r.RequestId
                )
            )
            BEGIN
                RAISERROR('Cannot archive Requests: Some records do not exist in reporting database', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            DELETE FROM [jit].[Requests]
            WHERE CreatedUtc < @CutoffDate;
            SET @RowsArchived = @RowsArchived + @@ROWCOUNT;
            PRINT 'Archived ' + CAST(@RequestsCount AS NVARCHAR(10)) + ' Requests';
        END
        ELSE IF @DryRun = 1
        BEGIN
            PRINT 'Would archive ' + CAST(@RequestsCount AS NVARCHAR(10)) + ' Requests';
        END

        -- Archive Grants (older than cutoff date, based on ValidFromUtc)
        SELECT @GrantsCount = COUNT(*)
        FROM [jit].[Grants]
        WHERE ValidFromUtc < @CutoffDate;

        IF @DryRun = 0 AND @GrantsCount > 0
        BEGIN
            -- Verify data exists in reporting DB
            IF EXISTS (
                SELECT 1 
                FROM [jit].[Grants] g
                WHERE g.ValidFromUtc < @CutoffDate
                AND NOT EXISTS (
                    SELECT 1 FROM [DMAP_JIT_Permissions_Reporting].[reporting].[Grants] rep
                    WHERE rep.GrantId = g.GrantId
                )
            )
            BEGIN
                RAISERROR('Cannot archive Grants: Some records do not exist in reporting database', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            DELETE FROM [jit].[Grants]
            WHERE ValidFromUtc < @CutoffDate;
            SET @RowsArchived = @RowsArchived + @@ROWCOUNT;
            PRINT 'Archived ' + CAST(@GrantsCount AS NVARCHAR(10)) + ' Grants';
        END
        ELSE IF @DryRun = 1
        BEGIN
            PRINT 'Would archive ' + CAST(@GrantsCount AS NVARCHAR(10)) + ' Grants';
        END

        -- Archive Approvals (older than cutoff date)
        SELECT @ApprovalsCount = COUNT(*)
        FROM [jit].[Approvals]
        WHERE DecisionUtc < @CutoffDate;

        IF @DryRun = 0 AND @ApprovalsCount > 0
        BEGIN
            -- Verify data exists in reporting DB
            IF EXISTS (
                SELECT 1 
                FROM [jit].[Approvals] a
                WHERE a.DecisionUtc < @CutoffDate
                AND NOT EXISTS (
                    SELECT 1 FROM [DMAP_JIT_Permissions_Reporting].[reporting].[Approvals] rep
                    WHERE rep.ApprovalId = a.ApprovalId
                )
            )
            BEGIN
                RAISERROR('Cannot archive Approvals: Some records do not exist in reporting database', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            DELETE FROM [jit].[Approvals]
            WHERE DecisionUtc < @CutoffDate;
            SET @RowsArchived = @RowsArchived + @@ROWCOUNT;
            PRINT 'Archived ' + CAST(@ApprovalsCount AS NVARCHAR(10)) + ' Approvals';
        END
        ELSE IF @DryRun = 1
        BEGIN
            PRINT 'Would archive ' + CAST(@ApprovalsCount AS NVARCHAR(10)) + ' Approvals';
        END

        -- Archive AuditLog (older than cutoff date)
        SELECT @AuditLogCount = COUNT(*)
        FROM [jit].[AuditLog]
        WHERE EventUtc < @CutoffDate;

        IF @DryRun = 0 AND @AuditLogCount > 0
        BEGIN
            -- Verify data exists in reporting DB
            IF EXISTS (
                SELECT 1 
                FROM [jit].[AuditLog] a
                WHERE a.EventUtc < @CutoffDate
                AND NOT EXISTS (
                    SELECT 1 FROM [DMAP_JIT_Permissions_Reporting].[reporting].[AuditLog] rep
                    WHERE rep.AuditId = a.AuditId
                )
            )
            BEGIN
                RAISERROR('Cannot archive AuditLog: Some records do not exist in reporting database', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            DELETE FROM [jit].[AuditLog]
            WHERE EventUtc < @CutoffDate;
            SET @RowsArchived = @RowsArchived + @@ROWCOUNT;
            PRINT 'Archived ' + CAST(@AuditLogCount AS NVARCHAR(10)) + ' AuditLog records';
        END
        ELSE IF @DryRun = 1
        BEGIN
            PRINT 'Would archive ' + CAST(@AuditLogCount AS NVARCHAR(10)) + ' AuditLog records';
        END

        IF @DryRun = 0
            COMMIT TRANSACTION;
        ELSE
            ROLLBACK TRANSACTION;

        PRINT 'Archive process completed. Total rows archived: ' + CAST(@RowsArchived AS NVARCHAR(10));

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'Archive process failed: ' + @ErrorMessage;
        THROW;
    END CATCH
END
GO
