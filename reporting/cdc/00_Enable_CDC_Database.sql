-- =============================================
-- Enable Change Data Capture (CDC) on Database
-- Requires SQL Server Enterprise Edition
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Check if CDC is already enabled
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DMAP_JIT_Permissions' AND is_cdc_enabled = 1)
BEGIN
    PRINT 'CDC is already enabled on database DMAP_JIT_Permissions'
END
ELSE
BEGIN
    -- Enable CDC on the database
    EXEC sys.sp_cdc_enable_db
    PRINT 'CDC enabled on database DMAP_JIT_Permissions'
END
GO

-- Verify CDC is enabled
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DMAP_JIT_Permissions' AND is_cdc_enabled = 1)
    PRINT 'CDC verification: Enabled'
ELSE
    THROW 50000, 'CDC could not be enabled. Please verify SQL Server Enterprise Edition is being used.', 1
GO
