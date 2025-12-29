-- =============================================
-- Test Data: Assign Users to Teams
-- =============================================
-- This script links users to teams
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT 'Assigning users to teams...'

-- Assign users to Data Engineering Team
INSERT INTO [jit].[User_Teams] (UserId, TeamId, IsActive, AssignedUtc)
SELECT u.UserId, t.TeamId, 1, GETUTCDATE()
FROM [jit].[Users] u
CROSS JOIN [jit].[Teams] t
WHERE u.LoginName IN ('DOMAIN\john.smith', 'DOMAIN\mike.wilson', 'DOMAIN\alex.taylor', 'DOMAIN\approver1')
AND t.TeamName = 'Data Engineering Team';

-- Assign users to Analytics Team
INSERT INTO [jit].[User_Teams] (UserId, TeamId, IsActive, AssignedUtc)
SELECT u.UserId, t.TeamId, 1, GETUTCDATE()
FROM [jit].[Users] u
CROSS JOIN [jit].[Teams] t
WHERE u.LoginName IN ('DOMAIN\emily.brown', 'DOMAIN\jessica.martin')
AND t.TeamName = 'Analytics Team';

-- Assign users to DevOps Team
INSERT INTO [jit].[User_Teams] (UserId, TeamId, IsActive, AssignedUtc)
SELECT u.UserId, t.TeamId, 1, GETUTCDATE()
FROM [jit].[Users] u
CROSS JOIN [jit].[Teams] t
WHERE u.LoginName = 'DOMAIN\david.lee'
AND t.TeamName = 'DevOps Team';

-- Assign users to Security Team
INSERT INTO [jit].[User_Teams] (UserId, TeamId, IsActive, AssignedUtc)
SELECT u.UserId, t.TeamId, 1, GETUTCDATE()
FROM [jit].[Users] u
CROSS JOIN [jit].[Teams] t
WHERE u.LoginName = 'DOMAIN\admin.user'
AND t.TeamName = 'Security Team';

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' user-team assignments created'

GO

