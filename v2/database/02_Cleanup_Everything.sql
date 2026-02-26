-- =============================================
-- Master Cleanup Script: Remove All JIT Framework Objects
-- This script removes all stored procedures and tables
-- =============================================
-- WARNING: This will delete ALL data and objects!
-- Use with caution. This script cannot be undone.
-- =============================================
-- Usage:
--   sqlcmd -S ServerName -d DatabaseName -i "02_Cleanup_Everything.sql"
--   Or enable SQLCMD mode in SSMS and run this script
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '========================================'
PRINT 'JIT Access Framework - Complete Cleanup'
PRINT '========================================'
PRINT ''
PRINT 'WARNING: This will delete ALL tables and stored procedures!'
PRINT 'All data will be permanently lost!'
PRINT ''
GO

-- =============================================
-- Step 1: Drop All Stored Procedures
-- =============================================

PRINT '========================================'
PRINT 'Step 1: Dropping Stored Procedures'
PRINT '========================================'
PRINT ''

-- Drop procedures in reverse dependency order
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Deny]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Deny]
GO
PRINT 'Dropped: sp_Request_Deny'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Approve]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Approve]
GO
PRINT 'Dropped: sp_Request_Approve'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Cancel]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Cancel]
GO
PRINT 'Dropped: sp_Request_Cancel'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_ListPendingForApprover]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_ListPendingForApprover]
GO
PRINT 'Dropped: sp_Request_ListPendingForApprover'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_ListForUser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_ListForUser]
GO
PRINT 'Dropped: sp_Request_ListForUser'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_GetRoles]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_GetRoles]
GO
PRINT 'Dropped: sp_Request_GetRoles'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Create]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Create]
GO
PRINT 'Dropped: sp_Request_Create'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Grant_ListActiveForUser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Grant_ListActiveForUser]
GO
PRINT 'Dropped: sp_Grant_ListActiveForUser'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Grant_Expire]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Grant_Expire]
GO
PRINT 'Dropped: sp_Grant_Expire'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Grant_Issue]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Grant_Issue]
GO
PRINT 'Dropped: sp_Grant_Issue'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Role_ListRequestable]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Role_ListRequestable]
GO
PRINT 'Dropped: sp_Role_ListRequestable'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Approver_CanApproveRequest]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Approver_CanApproveRequest]
GO
PRINT 'Dropped: sp_Approver_CanApproveRequest'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_User_Eligibility_Check]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_User_Eligibility_Check]
GO
PRINT 'Dropped: sp_User_Eligibility_Check'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_User_SyncFromAD]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_User_SyncFromAD]
GO
PRINT 'Dropped: sp_User_SyncFromAD'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_User_GetByLogin]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_User_GetByLogin]
GO
PRINT 'Dropped: sp_User_GetByLogin'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_User_ResolveCurrentUser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_User_ResolveCurrentUser]
GO
PRINT 'Dropped: sp_User_ResolveCurrentUser'

PRINT ''
PRINT 'All stored procedures dropped successfully!'
PRINT ''
GO


-- =============================================
-- Step 2: Drop All Tables (in reverse dependency order)
-- Tables must be dropped in order that respects foreign key constraints
-- =============================================

PRINT '========================================'
PRINT 'Step 2: Dropping Tables'
PRINT '========================================'
PRINT ''

-- Drop view first because it depends on Users and User_Context_Versions
IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[jit].[vw_User_CurrentContext]'))
    DROP VIEW [jit].[vw_User_CurrentContext]
GO
PRINT 'Dropped: vw_User_CurrentContext'

-- Drop tables in reverse dependency order (respecting foreign key dependencies)
-- Start with tables that have foreign keys pointing to other tables

-- Level 1: Tables that depend on Grants, Requests, Users, Roles
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[AuditLog]') AND type in (N'U'))
    DROP TABLE [jit].[AuditLog]
GO
PRINT 'Dropped: AuditLog'

-- Level 2: Tables that depend on Grants and DB_Roles
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Grant_DBRole_Assignments]') AND type in (N'U'))
    DROP TABLE [jit].[Grant_DBRole_Assignments]
GO
PRINT 'Dropped: Grant_DBRole_Assignments'

-- Level 3: Tables that depend on Requests and Roles
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Request_Roles]') AND type in (N'U'))
    DROP TABLE [jit].[Request_Roles]
GO
PRINT 'Dropped: Request_Roles'

-- Level 4: Tables that depend on Requests, Users, and Roles
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Grants]') AND type in (N'U'))
    DROP TABLE [jit].[Grants]
GO
PRINT 'Dropped: Grants'

-- Level 5: Tables that depend on Requests and Users
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Approvals]') AND type in (N'U'))
    DROP TABLE [jit].[Approvals]
GO
PRINT 'Dropped: Approvals'

-- Level 6: Tables that depend on Users
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Requests]') AND type in (N'U'))
    DROP TABLE [jit].[Requests]
GO
PRINT 'Dropped: Requests'

-- Level 7: Eligibility tables that depend on Users and Roles
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[User_To_Role_Eligibility]') AND type in (N'U'))
    DROP TABLE [jit].[User_To_Role_Eligibility]
GO
PRINT 'Dropped: User_To_Role_Eligibility'

-- Level 8: Eligibility tables that depend on Roles
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Role_Eligibility_Rules]') AND type in (N'U'))
    DROP TABLE [jit].[Role_Eligibility_Rules]
GO
PRINT 'Dropped: Role_Eligibility_Rules'

-- Level 9: Team membership table that depends on Users and Teams
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[User_Teams]') AND type in (N'U'))
    DROP TABLE [jit].[User_Teams]
GO
PRINT 'Dropped: User_Teams'

-- Level 10: Role mapping table that depends on Roles and DB_Roles
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Role_To_DB_Roles]') AND type in (N'U'))
    DROP TABLE [jit].[Role_To_DB_Roles]
GO
PRINT 'Dropped: Role_To_DB_Roles'

-- Level 11: Core tables with no dependencies on other jit tables
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[DB_Roles]') AND type in (N'U'))
    DROP TABLE [jit].[DB_Roles]
GO
PRINT 'Dropped: DB_Roles'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Teams]') AND type in (N'U'))
    DROP TABLE [jit].[Teams]
GO
PRINT 'Dropped: Teams'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Roles]') AND type in (N'U'))
    DROP TABLE [jit].[Roles]
GO
PRINT 'Dropped: Roles'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[User_Context_Versions]') AND type in (N'U'))
    DROP TABLE [jit].[User_Context_Versions]
GO
PRINT 'Dropped: User_Context_Versions'

-- Level 12: Users table (referenced by many tables, must be dropped last)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Users]') AND type in (N'U'))
    DROP TABLE [jit].[Users]
GO
PRINT 'Dropped: Users'

PRINT ''
PRINT 'All tables dropped successfully!'
PRINT ''
GO


-- =============================================
-- Step 3: Drop Schema (optional)
-- =============================================
/*
PRINT '========================================'
PRINT 'Step 3: Dropping Schema'
PRINT '========================================'
PRINT ''

IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'jit')
BEGIN
    DROP SCHEMA [jit]
    PRINT 'Dropped: jit schema'
END
ELSE
BEGIN
    PRINT 'Schema [jit] does not exist'
END

PRINT ''
PRINT 'Schema dropped successfully!'
PRINT ''
GO
*/

-- =============================================
-- Cleanup Complete
-- =============================================

PRINT ''
PRINT '========================================'
PRINT 'Cleanup Complete!'
PRINT '========================================'
PRINT ''
PRINT 'All JIT Framework objects have been removed.'
PRINT 'You can now run the deployment script to recreate everything.'
PRINT ''

GO
