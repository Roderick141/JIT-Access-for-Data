-- =============================================
-- Test Data: Insert Eligibility Rules
-- =============================================
-- This script creates eligibility rules for testing different scenarios
-- MaxDurationMinutes, RequiresJustification, RequiresApproval are now
-- canonical on eligibility rules (no longer on the Roles table).
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Inserting eligibility rules...'

DECLARE @NextRuleId INT = ISNULL((SELECT MAX(EligibilityRuleId) FROM [jit].[Role_Eligibility_Rules]), 0);

-- Rule 1: All users can request 'Read-Only Reports' (pre-approved, 7 days)
INSERT INTO [jit].[Role_Eligibility_Rules] (
    EligibilityRuleId, RoleId, ScopeType, ScopeValue, CanRequest, Priority,
    MaxDurationMinutes, RequiresJustification, RequiresApproval,
    IsActive, ValidFromUtc, CreatedBy, UpdatedBy
)
SELECT @NextRuleId + 1, RoleId, 'All', NULL, 1, 10,
    10080, 1, 0,
    1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles]
WHERE RoleName = 'Read-Only Reports' AND IsActive = 1;

-- Rule 2: All users can request 'Temporary Query Access' (pre-approved, 1 day)
INSERT INTO [jit].[Role_Eligibility_Rules] (
    EligibilityRuleId, RoleId, ScopeType, ScopeValue, CanRequest, Priority,
    MaxDurationMinutes, RequiresJustification, RequiresApproval,
    IsActive, ValidFromUtc, CreatedBy, UpdatedBy
)
SELECT @NextRuleId + 2, RoleId, 'All', NULL, 1, 10,
    1440, 1, 0,
    1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles]
WHERE RoleName = 'Temporary Query Access' AND IsActive = 1;

-- Rule 3: Only Data Engineering department can request 'Data Warehouse Reader' (3 days, requires approval)
INSERT INTO [jit].[Role_Eligibility_Rules] (
    EligibilityRuleId, RoleId, ScopeType, ScopeValue, CanRequest, Priority,
    MinSeniorityLevel, MaxDurationMinutes, RequiresJustification, RequiresApproval,
    IsActive, ValidFromUtc, CreatedBy, UpdatedBy
)
SELECT @NextRuleId + 3, RoleId, 'Department', 'Data Engineering', 1, 20,
    3, 4320, 1, 1,
    1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles]
WHERE RoleName = 'Data Warehouse Reader' AND IsActive = 1;

-- Rule 4: Only Data Engineering Team members can request 'Advanced Analytics' (7 days, requires approval)
INSERT INTO [jit].[Role_Eligibility_Rules] (
    EligibilityRuleId, RoleId, ScopeType, ScopeValue, CanRequest, Priority,
    MinSeniorityLevel, MaxDurationMinutes, RequiresJustification, RequiresApproval,
    IsActive, ValidFromUtc, CreatedBy, UpdatedBy
)
SELECT @NextRuleId + 4, r.RoleId, 'Team', CAST(t.TeamId AS NVARCHAR(255)), 1, 30,
    3, 10080, 1, 1,
    1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles] r
CROSS JOIN [jit].[Teams] t
WHERE r.RoleName = 'Advanced Analytics'
AND t.TeamName = 'Data Engineering Team'
AND r.IsActive = 1;

-- Rule 5: Only Engineering division can request 'Full Database Access' (1 day, requires approval + justification)
INSERT INTO [jit].[Role_Eligibility_Rules] (
    EligibilityRuleId, RoleId, ScopeType, ScopeValue, CanRequest, Priority,
    MaxDurationMinutes, RequiresJustification, RequiresApproval,
    IsActive, ValidFromUtc, CreatedBy, UpdatedBy
)
SELECT @NextRuleId + 5, RoleId, 'Division', 'Engineering', 1, 40,
    1440, 1, 1,
    1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles]
WHERE RoleName = 'Full Database Access' AND IsActive = 1;

-- Rule 6: Only Security team can request 'Data Administrator' (1 day, requires approval + justification)
INSERT INTO [jit].[Role_Eligibility_Rules] (
    EligibilityRuleId, RoleId, ScopeType, ScopeValue, CanRequest, Priority,
    MaxDurationMinutes, RequiresJustification, RequiresApproval,
    IsActive, ValidFromUtc, CreatedBy, UpdatedBy
)
SELECT @NextRuleId + 6, r.RoleId, 'Team', CAST(t.TeamId AS NVARCHAR(255)), 1, 50,
    1440, 1, 1,
    1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'
FROM [jit].[Roles] r
CROSS JOIN [jit].[Teams] t
WHERE r.RoleName = 'Data Administrator'
AND t.TeamName = 'Security Team'
AND r.IsActive = 1;

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' eligibility rules inserted'

GO
