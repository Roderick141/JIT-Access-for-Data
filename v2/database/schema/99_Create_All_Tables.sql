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

-- Ensure reruns are clean: drop tables in reverse dependency order first.
IF OBJECT_ID(N'[jit].[vw_User_CurrentContext]', N'V') IS NOT NULL DROP VIEW [jit].[vw_User_CurrentContext];
IF OBJECT_ID(N'[jit].[AuditLog]', N'U') IS NOT NULL DROP TABLE [jit].[AuditLog];
IF OBJECT_ID(N'[jit].[Grant_DBRole_Assignments]', N'U') IS NOT NULL DROP TABLE [jit].[Grant_DBRole_Assignments];
IF OBJECT_ID(N'[jit].[Approvals]', N'U') IS NOT NULL DROP TABLE [jit].[Approvals];
IF OBJECT_ID(N'[jit].[Request_Roles]', N'U') IS NOT NULL DROP TABLE [jit].[Request_Roles];
IF OBJECT_ID(N'[jit].[Grants]', N'U') IS NOT NULL DROP TABLE [jit].[Grants];
IF OBJECT_ID(N'[jit].[Requests]', N'U') IS NOT NULL DROP TABLE [jit].[Requests];
IF OBJECT_ID(N'[jit].[User_To_Role_Eligibility]', N'U') IS NOT NULL DROP TABLE [jit].[User_To_Role_Eligibility];
IF OBJECT_ID(N'[jit].[Role_Eligibility_Rules]', N'U') IS NOT NULL DROP TABLE [jit].[Role_Eligibility_Rules];
IF OBJECT_ID(N'[jit].[User_Teams]', N'U') IS NOT NULL DROP TABLE [jit].[User_Teams];
IF OBJECT_ID(N'[jit].[Role_To_DB_Roles]', N'U') IS NOT NULL DROP TABLE [jit].[Role_To_DB_Roles];
IF OBJECT_ID(N'[jit].[DB_Roles]', N'U') IS NOT NULL DROP TABLE [jit].[DB_Roles];
IF OBJECT_ID(N'[jit].[Teams]', N'U') IS NOT NULL DROP TABLE [jit].[Teams];
IF OBJECT_ID(N'[jit].[Roles]', N'U') IS NOT NULL DROP TABLE [jit].[Roles];
IF OBJECT_ID(N'[jit].[User_Context_Versions]', N'U') IS NOT NULL DROP TABLE [jit].[User_Context_Versions];
IF OBJECT_ID(N'[jit].[Users]', N'U') IS NOT NULL DROP TABLE [jit].[Users];
GO

-- Create schema first
:r ./schema/00_Create_jit_Schema.sql

-- Core identity and role tables (must be created first)
:r ./schema/01_Create_Users.sql
:r ./schema/01b_Create_User_Context_Versions.sql
:r ./schema/01c_Create_User_CurrentContext_View.sql
:r ./schema/02_Create_Roles.sql
:r ./schema/03_Create_DB_Roles.sql
:r ./schema/04_Create_Role_To_DB_Roles.sql

-- Team and eligibility tables
:r ./schema/05_Create_Teams.sql
:r ./schema/06_Create_User_Teams.sql
:r ./schema/07_Create_Role_Eligibility_Rules.sql
:r ./schema/08_Create_User_To_Role_Eligibility.sql

-- Workflow tables
:r ./schema/10_Create_Requests.sql
:r ./schema/15_Create_Request_Roles.sql
:r ./schema/11_Create_Approvals.sql
:r ./schema/12_Create_Grants.sql
:r ./schema/13_Create_Grant_DBRole_Assignments.sql

-- Audit table
:r ./schema/14_Create_AuditLog.sql

GO

-- Note: The :r commands above are SQLCMD syntax. If running in SSMS,
-- you may need to enable SQLCMD mode or run each script individually in order.

