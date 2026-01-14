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
:r "schema\00_Create_jit_Schema.sql"

-- Core identity and role tables (must be created first)
:r "schema\01_Create_Users.sql"
:r "schema\02_Create_Roles.sql"
:r "schema\03_Create_DB_Roles.sql"
:r "schema\04_Create_Role_To_DB_Roles.sql"

-- Team and eligibility tables
:r "schema\05_Create_Teams.sql"
:r "schema\06_Create_User_Teams.sql"
:r "schema\07_Create_Role_Eligibility_Rules.sql"
:r "schema\08_Create_User_To_Role_Eligibility.sql"

-- Workflow tables
:r "schema\10_Create_Requests.sql"
:r "schema\15_Create_Request_Roles.sql"
:r "schema\11_Create_Approvals.sql"
:r "schema\12_Create_Grants.sql"
:r "schema\13_Create_Grant_DBRole_Assignments.sql"

-- Audit table
:r "schema\14_Create_AuditLog.sql"

GO

-- Note: The :r commands above are SQLCMD syntax. If running in SSMS,
-- you may need to enable SQLCMD mode or run each script individually in order.

