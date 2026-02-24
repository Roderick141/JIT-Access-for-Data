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
        JSON_VALUE(value, '$.scopeType'),
        JSON_VALUE(value, '$.scopeValue'),
        ISNULL(TRY_CAST(JSON_VALUE(value, '$.canRequest') AS BIT), 1),
        ISNULL(TRY_CAST(JSON_VALUE(value, '$.priority') AS INT), 0),
        TRY_CAST(JSON_VALUE(value, '$.minSeniorityLevel') AS INT),
        ISNULL(TRY_CAST(JSON_VALUE(value, '$.maxDurationMinutes') AS INT), 1440),
        ISNULL(TRY_CAST(JSON_VALUE(value, '$.requiresJustification') AS BIT), 1),
        ISNULL(TRY_CAST(JSON_VALUE(value, '$.requiresApproval') AS BIT), 1),
        1,
        GETUTCDATE(),
        ISNULL(@ActorUserId, SUSER_SNAME()),
        ISNULL(@ActorUserId, SUSER_SNAME())
    FROM OPENJSON(@RulesJson);
END
GO
