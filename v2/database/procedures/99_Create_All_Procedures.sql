-- =============================================
-- Master Script: Create All JIT Framework Stored Procedures
-- This script creates all stored procedures in the correct dependency order
-- =============================================
-- Note: Run this script AFTER creating all tables
-- 
-- Dependency Order:
-- 1. User procedures (no dependencies)
-- 2. Grant procedures (needed by Request procedures)
-- 3. Request procedures (depend on Grant procedures)
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT '========================================'
PRINT 'Creating JIT Framework Stored Procedures'
PRINT '========================================'
PRINT ''

-- =============================================
-- Step 1: Identity Management Procedures
-- (No dependencies on other procedures)
-- =============================================
PRINT 'Step 1: Creating Identity Management Procedures...'
:r ./procedures/sp_User_ResolveCurrentUser.sql
:r ./procedures/sp_User_GetByLogin.sql
:r ./procedures/sp_User_SyncFromAD.sql
:r ./procedures/sp_User_Eligibility_Check.sql
:r ./procedures/sp_Approver_CanApproveRequest.sql
PRINT ''

-- =============================================
-- Step 2: Role Management Procedures
-- (Depends on sp_User_Eligibility_Check)
-- =============================================
PRINT 'Step 2: Creating Role Management Procedures...'
:r ./procedures/sp_Role_Create.sql
:r ./procedures/sp_Role_Update.sql
:r ./procedures/sp_Role_Delete.sql
:r ./procedures/sp_Role_ToggleEnabled.sql
:r ./procedures/sp_Role_ListWithStats.sql
:r ./procedures/sp_Role_ListUsers.sql
:r ./procedures/sp_Role_GetDbRoles.sql
:r ./procedures/sp_Role_SetDbRoles.sql
:r ./procedures/sp_Role_GetEligibilityRules.sql
:r ./procedures/sp_Role_SetEligibilityRules.sql
:r ./procedures/sp_DbRole_ListAvailable.sql
:r ./procedures/sp_Role_ListRequestable.sql
PRINT ''

-- =============================================
-- Step 3: Grant Management Procedures
-- (No dependencies, but MUST be created before Request procedures that call them)
-- =============================================
PRINT 'Step 3: Creating Grant Management Procedures...'
:r ./procedures/sp_Grant_Issue.sql
:r ./procedures/sp_Grant_Expire.sql
:r ./procedures/sp_Grant_ListActiveForUser.sql
PRINT ''

-- =============================================
-- Step 4: Request Workflow Procedures
-- (sp_Request_Create and sp_Request_Approve depend on sp_Grant_Issue)
-- (sp_Request_Create also depends on sp_User_Eligibility_Check)
-- =============================================
PRINT 'Step 4: Creating Request Workflow Procedures...'
:r ./procedures/sp_Request_Create.sql
:r ./procedures/sp_Request_GetRoles.sql
:r ./procedures/sp_Request_ListForUser.sql
:r ./procedures/sp_Request_ListPendingForApprover.sql
:r ./procedures/sp_Request_Cancel.sql
:r ./procedures/sp_Request_Approve.sql
:r ./procedures/sp_Request_Deny.sql
:r ./procedures/sp_Team_Create.sql
:r ./procedures/sp_Team_Update.sql
:r ./procedures/sp_Team_Delete.sql
:r ./procedures/sp_Team_ListWithStats.sql
:r ./procedures/sp_Team_GetMembers.sql
:r ./procedures/sp_Team_SetMembers.sql
:r ./procedures/sp_User_UpdateSystemRoles.sql
:r ./procedures/sp_User_ListPaginated.sql
:r ./procedures/sp_AuditLog_ListPaginated.sql
:r ./procedures/sp_AuditLog_GetStats.sql
:r ./procedures/sp_Stats_Dashboard.sql
:r ./procedures/sp_LookupValues.sql
PRINT ''

PRINT 'Procedure Dependencies:'
PRINT '  - sp_Role_ListRequestable depends on sp_User_Eligibility_Check'
PRINT '  - sp_Approver_CanApproveRequest checks all roles in a request (requires Request_Roles table)'
PRINT '  - sp_Request_Create depends on sp_User_Eligibility_Check and sp_Grant_Issue (supports multiple roles)'
PRINT '  - sp_Request_Approve depends on sp_Grant_Issue and sp_Approver_CanApproveRequest (creates grants for all roles)'
PRINT '  - sp_Request_ListPendingForApprover filters by approval capability for all roles in request'
PRINT '  - sp_Request_GetRoles is a helper procedure (no dependencies)'
PRINT ''
GO

-- Note: The :r commands above are SQLCMD syntax. If running in SSMS,
-- you may need to enable SQLCMD mode (Query > SQLCMD Mode) or run each script individually in order.
-- Alternatively, you can use PowerShell or another tool to concatenate and run all scripts.
