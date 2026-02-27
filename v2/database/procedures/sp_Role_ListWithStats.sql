USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Role_ListWithStats]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Role_ListWithStats]
GO
CREATE PROCEDURE [jit].[sp_Role_ListWithStats]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentUtc DATETIME2 = GETUTCDATE();

    ;WITH ActiveRoles AS (
        SELECT
            r.RoleId,
            r.RoleName,
            r.Description AS RoleDescription,
            r.SensitivityLevel,
            r.IconName,
            r.IconColor,
            r.IsEnabled,
            r.IsActive,
            ROW_NUMBER() OVER (PARTITION BY r.RoleId ORDER BY r.RoleVersionId DESC) AS rn
        FROM [jit].[Roles] r
        WHERE r.IsActive = 1
    ),
    RoleBase AS (
        SELECT
            ar.RoleId,
            ar.RoleName,
            ar.RoleDescription,
            ar.SensitivityLevel,
            ar.IconName,
            ar.IconColor,
            ar.IsEnabled,
            ar.IsActive
        FROM ActiveRoles ar
        WHERE ar.rn = 1
    ),
    ActiveUsers AS (
        SELECT
            u.UserId,
            u.Department,
            u.Division
        FROM [jit].[vw_User_CurrentContext] u
        WHERE u.IsEnabled = 1
    ),
    RuleAllow AS (
        SELECT DISTINCT
            rb.RoleId,
            u.UserId
        FROM RoleBase rb
        INNER JOIN [jit].[Role_Eligibility_Rules] rer
            ON rer.RoleId = rb.RoleId
            AND rer.IsActive = 1
            AND rer.CanRequest = 1
            AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentUtc)
            AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentUtc)
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
    ),
    OverrideAllow AS (
        SELECT DISTINCT
            ue.RoleId,
            ue.UserId
        FROM [jit].[User_To_Role_Eligibility] ue
        INNER JOIN ActiveUsers u
            ON u.UserId = ue.UserId
        INNER JOIN RoleBase rb
            ON rb.RoleId = ue.RoleId
        WHERE ue.CanRequest = 1
          AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= @CurrentUtc)
          AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= @CurrentUtc)
    ),
    OverrideDeny AS (
        SELECT DISTINCT
            ue.RoleId,
            ue.UserId
        FROM [jit].[User_To_Role_Eligibility] ue
        INNER JOIN ActiveUsers u
            ON u.UserId = ue.UserId
        INNER JOIN RoleBase rb
            ON rb.RoleId = ue.RoleId
        WHERE ue.CanRequest = 0
          AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= @CurrentUtc)
          AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= @CurrentUtc)
    ),
    EligibleUnion AS (
        SELECT RoleId, UserId FROM RuleAllow
        UNION
        SELECT RoleId, UserId FROM OverrideAllow
    ),
    EligibleUsers AS (
        SELECT
            eu.RoleId,
            eu.UserId
        FROM EligibleUnion eu
        LEFT JOIN OverrideDeny od
            ON od.RoleId = eu.RoleId
           AND od.UserId = eu.UserId
        WHERE od.UserId IS NULL
    ),
    ConnectedCounts AS (
        SELECT
            eu.RoleId,
            COUNT(DISTINCT eu.UserId) AS ConnectedUserCount
        FROM EligibleUsers eu
        GROUP BY eu.RoleId
    ),
    ActiveGrantCounts AS (
        SELECT
            g.RoleId,
            COUNT(DISTINCT g.UserId) AS ActiveGrantedUserCount
        FROM [jit].[Grants] g
        WHERE g.Status = 'Active'
          AND g.ValidToUtc > @CurrentUtc
        GROUP BY g.RoleId
    ),
    PermissionAgg AS (
        SELECT
            rb.RoleId,
            COUNT(DISTINCT dbr.DbRoleId) AS PermissionCount,
            STRING_AGG(dbr.DbRoleName, '|') AS PermissionNames
        FROM RoleBase rb
        LEFT JOIN [jit].[Role_To_DB_Roles] map
            ON map.RoleId = rb.RoleId
           AND map.IsActive = 1
           AND (map.ValidFromUtc IS NULL OR map.ValidFromUtc <= @CurrentUtc)
           AND (map.ValidToUtc IS NULL OR map.ValidToUtc >= @CurrentUtc)
        LEFT JOIN [jit].[DB_Roles] dbr
            ON dbr.DbRoleId = map.DbRoleId
        GROUP BY rb.RoleId
    )
    SELECT
        rb.RoleId,
        rb.RoleName,
        rb.RoleDescription,
        rb.SensitivityLevel,
        rb.IconName,
        rb.IconColor,
        rb.IsEnabled,
        rb.IsActive,
        ISNULL(cc.ConnectedUserCount, 0) AS ConnectedUserCount,
        ISNULL(ag.ActiveGrantedUserCount, 0) AS ActiveGrantedUserCount,
        ISNULL(pa.PermissionCount, 0) AS PermissionCount,
        ISNULL(pa.PermissionNames, '') AS PermissionNames
    FROM RoleBase rb
    LEFT JOIN ConnectedCounts cc
        ON cc.RoleId = rb.RoleId
    LEFT JOIN ActiveGrantCounts ag
        ON ag.RoleId = rb.RoleId
    LEFT JOIN PermissionAgg pa
        ON pa.RoleId = rb.RoleId
    ORDER BY rb.RoleName;
END
GO

