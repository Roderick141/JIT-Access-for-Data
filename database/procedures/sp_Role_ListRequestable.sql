-- =============================================
-- Stored Procedure: jit.sp_Role_ListRequestable
-- Returns roles user can request (based on eligibility rules + enabled)
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
    
    -- Get user's division and department for eligibility checks
    SELECT 
        @UserDivision = Division,
        @UserDepartment = Department
    FROM [jit].[Users]
    WHERE UserId = @UserId;
    
    -- Check each enabled role for eligibility and exclude roles user already has active grants for
    SELECT 
        r.RoleId,
        r.RoleName,
        r.Description,
        r.MaxDurationMinutes,
        r.RequiresTicket,
        r.TicketRegex,
        r.RequiresJustification,
        r.RequiresApproval,
        r.AutoApproveMinSeniority
    FROM [jit].[Roles] r
    WHERE r.IsEnabled = 1
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
    -- Check eligibility using full logic (matching sp_User_Eligibility_Check)
    -- Priority 1: If user has explicit override, use that (allow or deny)
    -- Priority 2: Otherwise, check scope-based rules
    AND (
        -- User override allows
        EXISTS (
            SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue
            WHERE ue.UserId = @UserId AND ue.RoleId = r.RoleId
            AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= @CurrentUtc)
            AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= @CurrentUtc)
            AND ue.CanRequest = 1
        )
        -- OR scope rules allow (only if no user override denies)
        OR (
            -- User-specific rules
            EXISTS (
                SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                WHERE rer.RoleId = r.RoleId
                AND rer.ScopeType = 'User'
                AND rer.ScopeValue = @UserId
                AND rer.CanRequest = 1
                AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentUtc)
                AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentUtc)
            )
            -- Team rules (user must be active member)
            OR EXISTS (
                SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                INNER JOIN [jit].[User_Teams] ut ON CAST(ut.TeamId AS NVARCHAR(255)) = rer.ScopeValue
                WHERE rer.RoleId = r.RoleId
                AND rer.ScopeType = 'Team'
                AND ut.UserId = @UserId
                AND ut.IsActive = 1
                AND rer.CanRequest = 1
                AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentUtc)
                AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentUtc)
            )
            -- Department rules
            OR EXISTS (
                SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                WHERE rer.RoleId = r.RoleId
                AND rer.ScopeType = 'Department'
                AND rer.ScopeValue = @UserDepartment
                AND @UserDepartment IS NOT NULL
                AND rer.CanRequest = 1
                AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentUtc)
                AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentUtc)
            )
            -- Division rules
            OR EXISTS (
                SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                WHERE rer.RoleId = r.RoleId
                AND rer.ScopeType = 'Division'
                AND rer.ScopeValue = @UserDivision
                AND @UserDivision IS NOT NULL
                AND rer.CanRequest = 1
                AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentUtc)
                AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentUtc)
            )
            -- All rules (lowest priority)
            OR EXISTS (
                SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                WHERE rer.RoleId = r.RoleId
                AND rer.ScopeType = 'All'
                AND rer.ScopeValue IS NULL
                AND rer.CanRequest = 1
                AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentUtc)
                AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentUtc)
            )
        )
        -- Exclude if user has explicit denial override
        AND NOT EXISTS (
            SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue
            WHERE ue.UserId = @UserId AND ue.RoleId = r.RoleId
            AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= @CurrentUtc)
            AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= @CurrentUtc)
            AND ue.CanRequest = 0
        )
    )
    ORDER BY r.RoleName;
END
GO

