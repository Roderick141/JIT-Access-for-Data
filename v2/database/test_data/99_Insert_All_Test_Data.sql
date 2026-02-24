-- =============================================
-- Master Script: Insert All Test Data
-- This script inserts all test data in the correct order
-- =============================================
-- WARNING: This will insert test data. Use only in test/dev environments!
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT '========================================'
PRINT 'Inserting JIT Framework Test Data'
PRINT '========================================'
PRINT ''
PRINT 'WARNING: This script will insert test data!'
PRINT 'Ensure you are running this in a test/development environment.'
PRINT ''
PRINT 'Press Ctrl+C to cancel, or wait 5 seconds to continue...'
WAITFOR DELAY '00:00:05'
PRINT ''

-- Check if data already exists
IF EXISTS (SELECT 1 FROM [jit].[Users])
BEGIN
    PRINT 'WARNING: Users table already contains data!'
    PRINT 'This script will attempt to insert additional test data.'
    PRINT 'You may need to clear existing data first if you want a clean slate.'
    PRINT ''
END

-- Clear existing test data (optional - uncomment if you want to start fresh)
/*
PRINT 'Clearing existing test data...'
DELETE FROM [jit].[AuditLog];
DELETE FROM [jit].[Grant_DBRole_Assignments];
DELETE FROM [jit].[Grants];
DELETE FROM [jit].[Approvals];
DELETE FROM [jit].[Request_Roles];
DELETE FROM [jit].[Requests];
DELETE FROM [jit].[User_To_Role_Eligibility]; 
DELETE FROM [jit].[Role_Eligibility_Rules];
DELETE FROM [jit].[User_Teams];
DELETE FROM [jit].[Teams];
DELETE FROM [jit].[Role_To_DB_Roles];
DELETE FROM [jit].[DB_Roles];
DELETE FROM [jit].[Roles];
DELETE FROM [jit].[Users];
PRINT 'Existing data cleared.'
PRINT ''
*/

-- Create database roles first (if needed)
PRINT 'Step 0: Creating database roles (if needed)...'
:r ./test_data/00_Create_Test_DB_Roles.sql

-- Insert test data in dependency order
PRINT ''
PRINT 'Step 1: Inserting users...'
:r ./test_data/01_Insert_Test_Users.sql

PRINT ''
PRINT 'Step 2: Inserting business roles...'
:r ./test_data/02_Insert_Test_Roles.sql

PRINT ''
PRINT 'Step 3: Inserting DB roles...'
:r ./test_data/03_Insert_Test_DB_Roles.sql

PRINT ''
PRINT 'Step 4: Mapping business roles to DB roles...'
:r ./test_data/04_Insert_Test_Role_Mappings.sql

PRINT ''
PRINT 'Step 5: Inserting teams...'
:r ./test_data/05_Insert_Test_Teams.sql

PRINT ''
PRINT 'Step 6: Assigning users to teams...'
:r ./test_data/06_Insert_Test_User_Teams.sql

PRINT ''
PRINT 'Step 7: Inserting eligibility rules...'
:r ./test_data/07_Insert_Test_Eligibility_Rules.sql

PRINT ''
PRINT 'Step 8: Inserting test requests...'
:r ./test_data/09_Insert_Test_Requests.sql

PRINT ''
PRINT 'Step 9a: Associating roles with requests...'
:r ./test_data/09a_Insert_Test_Request_Roles.sql

PRINT ''
PRINT 'Step 10: Inserting test grants...'
:r ./test_data/10_Insert_Test_Grants.sql

PRINT ''
PRINT 'Step 11: Inserting test approvals...'
:r ./test_data/11_Insert_Test_Approvals.sql

PRINT ''
PRINT '========================================'
PRINT 'Test data insertion complete!'
PRINT '========================================'
PRINT ''
PRINT 'Summary of test data:'
PRINT '  - Users: Check jit.Users table'
PRINT '  - Roles: Check jit.Roles table'
PRINT '  - Teams: Check jit.Teams table'
PRINT '  - Requests: Check jit.Requests table'
PRINT '  - Grants: Check jit.Grants table'
PRINT ''
PRINT 'Test scenarios available:'
PRINT '  1. Auto-approved requests (pre-approved roles)'
PRINT '  2. Pending requests (requiring approval)'
PRINT '  3. Multi-role requests (2-3 roles per request)'
PRINT '  4. Single-role requests (legacy compatibility)'
PRINT '  5. Seniority-based auto-approval (test with senior users)'
PRINT '  6. Eligibility rules (department, division, team-based)'
PRINT '  7. Expired grants (for testing expiry job)'
PRINT ''
PRINT 'Test users:'
PRINT '  - DOMAIN\john.smith (Senior - Level 4)'
PRINT '  - DOMAIN\mike.wilson (Mid - Level 3)'
PRINT '  - DOMAIN\alex.taylor (Junior - Level 1)'
PRINT '  - DOMAIN\approver1 (Approver)'
PRINT ''
GO

-- Note: The :r commands above are SQLCMD syntax. If running in SSMS,
-- you may need to enable SQLCMD mode (Query > SQLCMD Mode) or run each script individually in order.

