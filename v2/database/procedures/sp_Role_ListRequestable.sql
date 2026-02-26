-- =============================================
-- Stored Procedure: jit.sp_Role_ListRequestable
-- Returns roles user can request (based on eligibility rules + enabled)
-- Resolves the best matching eligibility rule per role and returns
-- its MaxDurationMinutes, RequiresJustification, RequiresApproval.
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Role_ListRequestable]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Role_ListRequestable]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Role_ListRequestable]
    @UserId NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUtc DATETIME2 = GETUTCDATE();
    DECLARE @UserDivision NVARCHAR(255);
    DECLARE @UserDepartment NVARCHAR(255);
    
    SELECT 
        @UserDivision = Division,
        @UserDepartment = Department
        FROM [jit].[vw_User_CurrentContext]
        WHERE UserId = @UserId
            AND IsEnabled = 1;
    
    SELECT 
        r.RoleId,
        r.RoleName,
        r.Description AS RoleDescription,
        r.SensitivityLevel,
        r.IconName,
        r.IconColor,
        matchedRule.MaxDurationMinutes,
        matchedRule.RequiresJustification,
        matchedRule.RequiresApproval
    FROM [jit].[Roles] r
    CROSS APPLY (
        SELECT TOP 1
            rer.MaxDurationMinutes,
            rer.RequiresJustification,
            rer.RequiresApproval
        FROM [jit].[Role_Eligibility_Rules] rer
        LEFT JOIN [jit].[User_Teams] ut
            ON rer.ScopeType = 'Team'
            AND CAST(ut.TeamId AS NVARCHAR(255)) = rer.ScopeValue
            AND ut.UserId = @UserId
            AND ut.IsActive = 1
        WHERE rer.RoleId = r.RoleId
        AND rer.IsActive = 1
        AND rer.CanRequest = 1
        AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentUtc)
        AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentUtc)
        AND (
            (rer.ScopeType = 'User' AND rer.ScopeValue = CAST(@UserId AS NVARCHAR(255)))
            OR (rer.ScopeType = 'Team' AND ut.UserId IS NOT NULL)
            OR (rer.ScopeType = 'Department' AND rer.ScopeValue = @UserDepartment AND @UserDepartment IS NOT NULL)
            OR (rer.ScopeType = 'Division' AND rer.ScopeValue = @UserDivision AND @UserDivision IS NOT NULL)
            OR (rer.ScopeType = 'All' AND rer.ScopeValue IS NULL)
        )
        ORDER BY
            CASE rer.ScopeType
                WHEN 'User' THEN 5
                WHEN 'Team' THEN 4
                WHEN 'Department' THEN 3
                WHEN 'Division' THEN 2
                WHEN 'All' THEN 1
            END DESC,
            rer.Priority DESC
    ) AS matchedRule
    WHERE r.IsEnabled = 1 AND r.IsActive = 1
    -- Exclude roles with explicit user override denial
    AND NOT EXISTS (
        SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue
        WHERE ue.UserId = @UserId AND ue.RoleId = r.RoleId
        AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= @CurrentUtc)
        AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= @CurrentUtc)
        AND ue.CanRequest = 0
    )
    -- Exclude roles user already has active grants for
    AND NOT EXISTS (
        SELECT 1 FROM [jit].[Grants] g
        WHERE g.UserId = @UserId
        AND g.RoleId = r.RoleId
        AND g.Status = 'Active'
        AND g.ValidToUtc > @CurrentUtc
    )
    -- Exclude roles user already has pending requests for
    AND NOT EXISTS (
        SELECT 1 FROM [jit].[Requests] req
        INNER JOIN [jit].[Request_Roles] rr ON req.RequestId = rr.RequestId
        WHERE req.UserId = @UserId
        AND rr.RoleId = r.RoleId
        AND req.Status IN ('Pending', 'AutoApproved')
    )
    ORDER BY r.RoleName;
END
GO
