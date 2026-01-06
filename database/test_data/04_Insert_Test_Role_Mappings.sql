-- =============================================
-- Test Data: Map Business Roles to DB Roles
-- =============================================
-- This script links business roles to database roles
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Mapping business roles to DB roles...'

-- Map 'Read-Only Reports' to reporting reader role
INSERT INTO [jit].[Role_To_DB_Roles] (RoleId, DbRoleId, IsRequired)
SELECT r.RoleId, dbr.DbRoleId, 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[DB_Roles] dbr
WHERE r.RoleName = 'Read-Only Reports'
AND dbr.DbRoleName = 'JIT_Reports_Reader';

-- Map 'Advanced Analytics' to analytics role
INSERT INTO [jit].[Role_To_DB_Roles] (RoleId, DbRoleId, IsRequired)
SELECT r.RoleId, dbr.DbRoleId, 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[DB_Roles] dbr
WHERE r.RoleName = 'Advanced Analytics'
AND dbr.DbRoleName = 'JIT_Analytics';

-- Map 'Data Warehouse Reader' to standard datareader
INSERT INTO [jit].[Role_To_DB_Roles] (RoleId, DbRoleId, IsRequired)
SELECT r.RoleId, dbr.DbRoleId, 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[DB_Roles] dbr
WHERE r.RoleName = 'Data Warehouse Reader'
AND dbr.DbRoleName = 'db_datareader';

-- Map 'Full Database Access' to both reader and writer
INSERT INTO [jit].[Role_To_DB_Roles] (RoleId, DbRoleId, IsRequired)
SELECT r.RoleId, dbr.DbRoleId, 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[DB_Roles] dbr
WHERE r.RoleName = 'Full Database Access'
AND dbr.DbRoleName IN ('db_datareader', 'db_datawriter');

-- Map 'Data Administrator' to all roles
INSERT INTO [jit].[Role_To_DB_Roles] (RoleId, DbRoleId, IsRequired)
SELECT r.RoleId, dbr.DbRoleId, 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[DB_Roles] dbr
WHERE r.RoleName = 'Data Administrator'
AND dbr.DbRoleName IN ('db_datareader', 'db_datawriter', 'JIT_Reports_Unmasked');

-- Map 'Temporary Query Access' to standard datareader
INSERT INTO [jit].[Role_To_DB_Roles] (RoleId, DbRoleId, IsRequired)
SELECT r.RoleId, dbr.DbRoleId, 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[DB_Roles] dbr
WHERE r.RoleName = 'Temporary Query Access'
AND dbr.DbRoleName = 'db_datareader';

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' role mappings created'

GO

