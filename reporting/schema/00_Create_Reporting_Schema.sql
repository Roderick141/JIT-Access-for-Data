-- =============================================
-- Create Reporting Schema
-- Schema for reporting database
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Create reporting schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'reporting')
BEGIN
    EXEC('CREATE SCHEMA [reporting]')
END
GO
