-- =============================================
-- Master Deployment Script: Deploy Complete JIT Framework
-- This script deploys schema, stored procedures, and test data
-- =============================================
-- Usage:
--   sqlcmd -S ServerName -d DatabaseName -i "01_Deploy_Everything.sql"
--   Or enable SQLCMD mode in SSMS and run this script
-- =============================================

PRINT '========================================'
PRINT 'JIT Access Framework - Full Deployment'
PRINT '========================================'
PRINT ''
PRINT 'This script will:'
PRINT '  1. Create database schema (tables)'
PRINT '  2. Create all stored procedures'
PRINT '  3. Insert test data (optional)'
PRINT ''
PRINT 'Starting deployment...'
PRINT ''
GO

USE [DMAP_JIT_Permissions]
GO

-- =============================================
-- Step 1: Create Database Schema (Tables)
-- =============================================
PRINT '========================================'
PRINT 'Step 1: Creating Database Schema'
PRINT '========================================'
PRINT ''

:r "schema\99_Create_All_Tables.sql"

PRINT ''
PRINT 'Schema creation completed!'
PRINT ''

-- =============================================
-- Step 2: Create All Stored Procedures
-- =============================================
PRINT '========================================'
PRINT 'Step 2: Creating Stored Procedures'
PRINT '========================================'
PRINT ''

:r "procedures\99_Create_All_Procedures.sql"

PRINT ''
PRINT 'Stored procedures creation completed!'
PRINT ''

-- =============================================
-- Step 3: Insert Test Data (Optional)
-- =============================================
-- Uncomment the section below to deploy test data
-- WARNING: This will insert sample data. Only use for development/testing!

/*
PRINT '========================================'
PRINT 'Step 3: Inserting Test Data'
PRINT '========================================'
PRINT ''

:r "test_data\99_Insert_All_Test_Data.sql"

PRINT ''
PRINT 'Test data insertion completed!'
PRINT ''
*/

-- =============================================
-- Deployment Complete
-- =============================================
PRINT ''
PRINT '========================================'
PRINT 'Deployment Complete!'
PRINT '========================================'
PRINT ''
PRINT 'Next steps:'
PRINT '  1. Verify all tables were created successfully'
PRINT '  2. Verify all stored procedures were created successfully'
PRINT '  3. (Optional) Uncomment test data section above and re-run to insert test data'
PRINT '  4. Set up admin users: UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = ''DOMAIN\adminuser'''
PRINT '  5. Configure service account permissions'
PRINT ''
GO

