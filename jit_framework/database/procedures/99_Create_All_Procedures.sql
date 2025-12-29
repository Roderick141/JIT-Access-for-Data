-- =============================================
-- Master Script: Create All JIT Framework Stored Procedures
-- This script creates all stored procedures in the correct order
-- =============================================
-- Note: Run this script AFTER creating all tables
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT '========================================'
PRINT 'Creating JIT Framework Stored Procedures'
PRINT '========================================'
PRINT ''

-- Identity Management Procedures (must be created first)
PRINT 'Creating Identity Management Procedures...'
:r "sp_User_ResolveCurrentUser.sql"
:r "sp_User_GetByLogin.sql"
:r "sp_User_SyncFromAD.sql"
:r "sp_User_Eligibility_Check.sql"

-- Role Management Procedures
PRINT 'Creating Role Management Procedures...'
:r "sp_Role_ListRequestable.sql"

-- Workflow Procedures - Requests
PRINT 'Creating Request Workflow Procedures...'
:r "sp_Request_Create.sql"
:r "sp_Request_ListForUser.sql"
:r "sp_Request_ListPendingForApprover.sql"
:r "sp_Request_Cancel.sql"
:r "sp_Request_Approve.sql"
:r "sp_Request_Deny.sql"

-- Grant Management Procedures
PRINT 'Creating Grant Management Procedures...'
:r "sp_Grant_Issue.sql"
:r "sp_Grant_Expire.sql"
:r "sp_Grant_ListActiveForUser.sql"

PRINT ''
PRINT '========================================'
PRINT 'All stored procedures created successfully!'
PRINT '========================================'
GO

-- Note: The :r commands above are SQLCMD syntax. If running in SSMS,
-- you may need to enable SQLCMD mode (Query > SQLCMD Mode) or run each script individually in order.
-- Alternatively, you can use PowerShell or another tool to concatenate and run all scripts.

