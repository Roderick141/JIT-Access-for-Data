USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Role_SetEligibilityRules]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Role_SetEligibilityRules]
GO
CREATE PROCEDURE [jit].[sp_Role_SetEligibilityRules]
    @RoleId INT,
    @RulesJson NVARCHAR(MAX),
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [jit].[Role_Eligibility_Rules]
    SET IsActive = 0, ValidToUtc = GETUTCDATE(), UpdatedUtc = GETUTCDATE(), UpdatedBy = ISNULL(@ActorUserId, SUSER_SNAME())
    WHERE RoleId = @RoleId AND IsActive = 1;

    INSERT INTO [jit].[Role_Eligibility_Rules] (
        EligibilityRuleId, RoleId, ScopeType, ScopeValue, CanRequest, Priority,
        MinSeniorityLevel, MaxDurationMinutes, RequiresJustification, RequiresApproval,
        IsActive, ValidFromUtc, CreatedBy, UpdatedBy
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY (SELECT 1)) + ISNULL((SELECT MAX(EligibilityRuleId) FROM [jit].[Role_Eligibility_Rules]), 0),
        @RoleId,
        j.ScopeType,
        j.ScopeValue,
        ISNULL(j.CanRequest, 1),
        ISNULL(j.Priority, 0),
        j.MinSeniorityLevel,
        ISNULL(j.MaxDurationMinutes, 1440),
        ISNULL(j.RequiresJustification, 1),
        ISNULL(j.RequiresApproval, 1),
        1,
        GETUTCDATE(),
        ISNULL(@ActorUserId, SUSER_SNAME()),
        ISNULL(@ActorUserId, SUSER_SNAME())
    FROM OPENJSON(@RulesJson)
    WITH (
        ScopeType NVARCHAR(4000) '$.scopeType',
        ScopeValue NVARCHAR(4000) '$.scopeValue',
        CanRequest BIT '$.canRequest',
        Priority INT '$.priority',
        MinSeniorityLevel INT '$.minSeniorityLevel',
        MaxDurationMinutes INT '$.maxDurationMinutes',
        RequiresJustification BIT '$.requiresJustification',
        RequiresApproval BIT '$.requiresApproval'
    ) j;
END
GO
