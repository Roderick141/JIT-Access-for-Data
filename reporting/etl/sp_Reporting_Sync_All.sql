-- =============================================
-- Master ETL Procedure: Sync All Tables
-- Calls all individual sync procedures
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Sync_All]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Sync_All]
GO

CREATE PROCEDURE [reporting].[sp_Reporting_Sync_All]
    @FullSync BIT = 0  -- If 1, performs full sync (for initial load)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMessage NVARCHAR(MAX);

    BEGIN TRY
        PRINT 'Starting ETL Sync - FullSync: ' + CASE WHEN @FullSync = 1 THEN 'Yes' ELSE 'No' END;

        -- Sync dimension tables first
        EXEC [reporting].[sp_Reporting_Sync_Users] @FullSync = @FullSync;
        EXEC [reporting].[sp_Reporting_Sync_Roles] @FullSync = @FullSync;

        -- Sync fact tables
        EXEC [reporting].[sp_Reporting_Sync_Requests] @FullSync = @FullSync;
        EXEC [reporting].[sp_Reporting_Sync_Grants] @FullSync = @FullSync;
        EXEC [reporting].[sp_Reporting_Sync_Approvals] @FullSync = @FullSync;
        EXEC [reporting].[sp_Reporting_Sync_Request_Roles] @FullSync = @FullSync;

        -- Sync AuditLog (copy-based)
        EXEC [reporting].[sp_Reporting_Sync_AuditLog] @FullSync = @FullSync;

        PRINT 'ETL Sync completed successfully';

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'ETL Sync failed: ' + @ErrorMessage;
        THROW;
    END CATCH
END
GO
