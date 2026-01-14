-- =============================================
-- Helper Procedure: Log ETL Operation
-- Logs ETL operations to reporting.ETL_Log
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[sp_Reporting_Helper_LogETL]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [reporting].[sp_Reporting_Helper_LogETL]
GO

CREATE PROCEDURE [reporting].[sp_Reporting_Helper_LogETL]
    @TableName NVARCHAR(128),
    @Operation NVARCHAR(50),
    @Status NVARCHAR(50),
    @RowsProcessed INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @Details NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [reporting].[ETL_Log]
        (TableName, Operation, Status, RowsProcessed, ErrorMessage, Details)
    VALUES
        (@TableName, @Operation, @Status, @RowsProcessed, @ErrorMessage, @Details);
END
GO
