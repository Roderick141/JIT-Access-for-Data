-- =============================================
-- Master Script: Create All JIT Framework Tables
-- This script creates all tables in the correct order
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT '========================================'
PRINT 'Creating JIT Framework Database Schema'
PRINT '========================================'
PRINT ''

-- Create schema first
:r "00_Create_jit_Schema.sql"

-- Core identity and role tables (must be created first)
:r "01_Create_Users.sql"
:r "02_Create_Roles.sql"
:r "03_Create_DB_Roles.sql"
:r "04_Create_Role_To_DB_Roles.sql"

-- Team and eligibility tables
:r "05_Create_Teams.sql"
:r "06_Create_User_Teams.sql"
:r "07_Create_Role_Eligibility_Rules.sql"
:r "08_Create_User_To_Role_Eligibility.sql"
:r "09_Create_Role_Approvers.sql"

-- Workflow tables
:r "10_Create_Requests.sql"
:r "11_Create_Approvals.sql"
:r "12_Create_Grants.sql"
:r "13_Create_Grant_DBRole_Assignments.sql"

-- Audit table
:r "14_Create_AuditLog.sql"

PRINT ''
PRINT '========================================'
PRINT 'All tables created successfully!'
PRINT '========================================'
GO

-- Note: The :r commands above are SQLCMD syntax. If running in SSMS,
-- you may need to enable SQLCMD mode or run each script individually in order.

