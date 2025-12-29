-- =============================================
-- Create Test Database Roles
-- =============================================
-- This script creates the database roles needed for testing
-- Run this BEFORE inserting test data
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT 'Creating test database roles...'
PRINT ''

-- Check if roles exist and create them if they don't
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'JIT_Reports_Reader' AND type = 'R')
BEGIN
    CREATE ROLE [JIT_Reports_Reader];
    PRINT 'Created role: JIT_Reports_Reader';
    -- Example: Grant SELECT on a schema (adjust as needed)
    -- GRANT SELECT ON SCHEMA::dbo TO [JIT_Reports_Reader];
END
ELSE
BEGIN
    PRINT 'Role JIT_Reports_Reader already exists';
END

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'JIT_Reports_Unmasked' AND type = 'R')
BEGIN
    CREATE ROLE [JIT_Reports_Unmasked];
    PRINT 'Created role: JIT_Reports_Unmasked';
    -- Example: Grant SELECT and UNMASK permissions (adjust as needed)
    -- GRANT SELECT ON SCHEMA::dbo TO [JIT_Reports_Unmasked];
    -- GRANT UNMASK TO [JIT_Reports_Unmasked];
END
ELSE
BEGIN
    PRINT 'Role JIT_Reports_Unmasked already exists';
END

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'JIT_Analytics' AND type = 'R')
BEGIN
    CREATE ROLE [JIT_Analytics];
    PRINT 'Created role: JIT_Analytics';
    -- Example: Grant SELECT on analytics views/tables (adjust as needed)
    -- GRANT SELECT ON SCHEMA::Analytics TO [JIT_Analytics];
END
ELSE
BEGIN
    PRINT 'Role JIT_Analytics already exists';
END

PRINT ''
PRINT 'Database roles created successfully!'
PRINT ''
PRINT 'NOTE: You may need to grant appropriate permissions to these roles'
PRINT 'based on your actual database schema. Examples:'
PRINT '  GRANT SELECT ON SCHEMA::dbo TO [JIT_Reports_Reader];'
PRINT '  GRANT SELECT ON SCHEMA::dbo TO [JIT_Reports_Unmasked];'
PRINT '  GRANT UNMASK TO [JIT_Reports_Unmasked];'
PRINT '  GRANT SELECT ON SCHEMA::Analytics TO [JIT_Analytics];'
GO

