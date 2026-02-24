USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Role_ListUsers]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Role_ListUsers]
GO
CREATE PROCEDURE [jit].[sp_Role_ListUsers]
    @RoleId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentUtc DATETIME2 = GETUTCDATE();

    ;WITH ActiveUsers AS (
        SELECT
            u.UserId,
            u.LoginName,
            u.DisplayName,
            u.Email,
            u.Department,
            u.Division,
            u.SeniorityLevel
        FROM [jit].[Users] u
        WHERE u.IsActive = 1
    ),
    RuleAllow AS (
        SELECT DISTINCT
            u.UserId
        FROM [jit].[Role_Eligibility_Rules] rer
        INNER JOIN ActiveUsers u
            ON (
                (rer.ScopeType = 'User' AND rer.ScopeValue = u.UserId)
                OR (rer.ScopeType = 'Department' AND rer.ScopeValue = u.Department AND u.Department IS NOT NULL)
                OR (rer.ScopeType = 'Division' AND rer.ScopeValue = u.Division AND u.Division IS NOT NULL)
                OR (rer.ScopeType = 'All' AND (rer.ScopeValue IS NULL OR LTRIM(RTRIM(rer.ScopeValue)) = ''))
                OR (
                    rer.ScopeType = 'Team'
                    AND EXISTS (
                        SELECT 1
                        FROM [jit].[User_Teams] ut
                        WHERE ut.UserId = u.UserId
                          AND ut.IsActive = 1
                          AND (ut.ValidFromUtc IS NULL OR ut.ValidFromUtc <= @CurrentUtc)
                          AND (ut.ValidToUtc IS NULL OR ut.ValidToUtc >= @CurrentUtc)
                          AND CAST(ut.TeamId AS NVARCHAR(255)) = rer.ScopeValue
                    )
                )
            )
            AND (rer.MinSeniorityLevel IS NULL OR ISNULL(u.SeniorityLevel, 0) >= rer.MinSeniorityLevel)
        WHERE rer.RoleId = @RoleId
          AND rer.IsActive = 1
          AND rer.CanRequest = 1
          AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentUtc)
          AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentUtc)
    ),
    OverrideAllow AS (
        SELECT DISTINCT
            ue.UserId
        FROM [jit].[User_To_Role_Eligibility] ue
        INNER JOIN ActiveUsers u
            ON u.UserId = ue.UserId
        WHERE ue.RoleId = @RoleId
          AND ue.CanRequest = 1
          AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= @CurrentUtc)
          AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= @CurrentUtc)
    ),
    OverrideDeny AS (
        SELECT DISTINCT
            ue.UserId
        FROM [jit].[User_To_Role_Eligibility] ue
        INNER JOIN ActiveUsers u
            ON u.UserId = ue.UserId
        WHERE ue.RoleId = @RoleId
          AND ue.CanRequest = 0
          AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= @CurrentUtc)
          AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= @CurrentUtc)
    ),
    EligibleUnion AS (
        SELECT UserId FROM RuleAllow
        UNION
        SELECT UserId FROM OverrideAllow
    ),
    EligibleUsers AS (
        SELECT eu.UserId
        FROM EligibleUnion eu
        LEFT JOIN OverrideDeny od
            ON od.UserId = eu.UserId
        WHERE od.UserId IS NULL
    ),
    ActiveGrants AS (
        SELECT
            g.UserId,
            MAX(g.ValidFromUtc) AS GrantedDateUtc,
            MAX(g.ValidToUtc) AS ExpiryDateUtc
        FROM [jit].[Grants] g
        WHERE g.RoleId = @RoleId
          AND g.Status = 'Active'
          AND g.ValidToUtc > @CurrentUtc
        GROUP BY g.UserId
    )
    SELECT
        u.UserId,
        u.LoginName,
        u.DisplayName,
        u.Email,
        u.Department,
        CASE WHEN ag.UserId IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS HasActiveRole,
        ag.GrantedDateUtc,
        ag.ExpiryDateUtc
    FROM EligibleUsers eu
    INNER JOIN ActiveUsers u
        ON u.UserId = eu.UserId
    LEFT JOIN ActiveGrants ag
        ON ag.UserId = u.UserId
    ORDER BY u.DisplayName, u.UserId;
END
GO

