-- =============================================
-- Test Data: Insert Eligibility Rules
-- =============================================
-- This script creates eligibility rules for testing different scenarios
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT 'Inserting eligibility rules...'

-- Rule 1: All users can request 'Read-Only Reports' (pre-approved role)
INSERT INTO [jit].[Role_Eligibility_Rules] (
    RoleId, ScopeType, ScopeValue, CanRequest, Priority, CreatedBy, UpdatedBy
)
SELECT RoleId, 'All', NULL, 1, 10, 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles]
WHERE RoleName = 'Read-Only Reports';

-- Rule 2: All users can request 'Temporary Query Access' (pre-approved)
INSERT INTO [jit].[Role_Eligibility_Rules] (
    RoleId, ScopeType, ScopeValue, CanRequest, Priority, CreatedBy, UpdatedBy
)
SELECT RoleId, 'All', NULL, 1, 10, 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles]
WHERE RoleName = 'Temporary Query Access';

-- Rule 3: Only Data Engineering department can request 'Data Warehouse Reader'
INSERT INTO [jit].[Role_Eligibility_Rules] (
    RoleId, ScopeType, ScopeValue, CanRequest, Priority, CreatedBy, UpdatedBy
)
SELECT RoleId, 'Department', 'Data Engineering', 1, 20, 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles]
WHERE RoleName = 'Data Warehouse Reader';

-- Rule 4: Only Data Engineering Team members can request 'Advanced Analytics'
INSERT INTO [jit].[Role_Eligibility_Rules] (
    RoleId, ScopeType, ScopeValue, CanRequest, Priority, CreatedBy, UpdatedBy
)
SELECT r.RoleId, 'Team', CAST(t.TeamId AS NVARCHAR(255)), 1, 30, 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles] r
CROSS JOIN [jit].[Teams] t
WHERE r.RoleName = 'Advanced Analytics'
AND t.TeamName = 'Data Engineering Team';

-- Rule 5: Only Engineering division can request 'Full Database Access'
INSERT INTO [jit].[Role_Eligibility_Rules] (
    RoleId, ScopeType, ScopeValue, CanRequest, Priority, CreatedBy, UpdatedBy
)
SELECT RoleId, 'Division', 'Engineering', 1, 40, 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles]
WHERE RoleName = 'Full Database Access';

-- Rule 6: Only Security team can request 'Data Administrator'
INSERT INTO [jit].[Role_Eligibility_Rules] (
    RoleId, ScopeType, ScopeValue, CanRequest, Priority, CreatedBy, UpdatedBy
)
SELECT r.RoleId, 'Team', CAST(t.TeamId AS NVARCHAR(255)), 1, 50, 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles] r
CROSS JOIN [jit].[Teams] t
WHERE r.RoleName = 'Data Administrator'
AND t.TeamName = 'Security Team';

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' eligibility rules inserted'

GO

