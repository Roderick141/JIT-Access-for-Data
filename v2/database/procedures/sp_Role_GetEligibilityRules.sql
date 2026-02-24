USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Role_GetEligibilityRules]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Role_GetEligibilityRules]
GO
CREATE PROCEDURE [jit].[sp_Role_GetEligibilityRules]
    @RoleId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM [jit].[Role_Eligibility_Rules]
    WHERE RoleId = @RoleId AND IsActive = 1
    ORDER BY Priority DESC, EligibilityRuleVersionId DESC;
END
GO

