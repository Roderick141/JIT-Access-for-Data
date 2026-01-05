-- =============================================
-- Test Data: Insert Role Approvers
-- =============================================
-- This script sets up approvers for roles that require approval
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Setting up role approvers...'

-- Set approvers for 'Advanced Analytics' (requires approval for junior users)
INSERT INTO [jit].[Role_Approvers] (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[Users] u
WHERE r.RoleName = 'Advanced Analytics'
AND u.LoginName = 'DOMAIN\approver1';

-- Set approvers for 'Data Warehouse Reader'
INSERT INTO [jit].[Role_Approvers] (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[Users] u
WHERE r.RoleName = 'Data Warehouse Reader'
AND u.LoginName = 'DOMAIN\john.smith';

-- Set approvers for 'Full Database Access' (multiple approvers)
INSERT INTO [jit].[Role_Approvers] (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[Users] u
WHERE r.RoleName = 'Full Database Access'
AND u.LoginName = 'DOMAIN\admin.user';

INSERT INTO [jit].[Role_Approvers] (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 2
FROM [jit].[Roles] r
CROSS JOIN [jit].[Users] u
WHERE r.RoleName = 'Full Database Access'
AND u.LoginName = 'DOMAIN\sarah.jones';

-- Set approver for 'Data Administrator'
INSERT INTO [jit].[Role_Approvers] (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
FROM [jit].[Roles] r
CROSS JOIN [jit].[Users] u
WHERE r.RoleName = 'Data Administrator'
AND u.LoginName = 'DOMAIN\admin.user';

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' approver assignments created'

GO

