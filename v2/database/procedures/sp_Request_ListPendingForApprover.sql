-- =============================================
-- Stored Procedure: jit.sp_Request_ListPendingForApprover
-- Returns pending requests for a specific approver
-- Used by approver portal
-- Now supports multiple roles per request - only shows requests where approver can approve ALL roles
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_ListPendingForApprover]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_ListPendingForApprover]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Request_ListPendingForApprover]
    @ApproverUserId NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ApproverDivision NVARCHAR(255);
    DECLARE @ApproverDepartment NVARCHAR(255);
    DECLARE @ApproverSeniority INT;
    DECLARE @ApproverIsAdmin BIT;
    DECLARE @ApproverIsDataSteward BIT;
    DECLARE @ApproverIsApprover BIT;
    DECLARE @CanApprove BIT;
    DECLARE @ApprovalReason NVARCHAR(100);
    
    -- Get approver details once
    SELECT 
        @ApproverDivision = Division,
        @ApproverDepartment = Department,
        @ApproverSeniority = SeniorityLevel,
        @ApproverIsAdmin = IsAdmin,
        @ApproverIsDataSteward = IsDataSteward,
        @ApproverIsApprover = IsApprover
    FROM [jit].[Users]
    WHERE UserId = @ApproverUserId;
    
    -- Get requests where approver can approve ALL roles
    SELECT DISTINCT
        r.RequestId,
        r.UserId,
        u.DisplayName AS RequesterName,
        u.LoginName AS RequesterLoginName,
        u.Email AS RequesterEmail,
        u.Department AS RequesterDepartment,
        u.Division AS RequesterDivision,
        u.SeniorityLevel AS RequesterSeniority,
        STRING_AGG(rol.RoleName, ', ') AS RoleNames,
        MAX(rol.SensitivityLevel) AS SensitivityLevel,
        COUNT(rr.RoleId) AS RoleCount,
        r.RequestedDurationMinutes,
        r.Justification,
        r.TicketRef,
        r.UserDeptSnapshot,
        r.UserTitleSnapshot,
        r.CreatedUtc,
        r.Status,
        -- Approval reason (check if approver can approve all roles)
        CASE
            WHEN @ApproverIsAdmin = 1 THEN 'Admin'
            WHEN @ApproverIsDataSteward = 1 
                 AND @ApproverDivision IS NOT NULL 
                 AND u.Division IS NOT NULL 
                 AND @ApproverDivision = u.Division THEN 'DataSteward'
            WHEN @ApproverIsApprover = 1 
                 AND @ApproverDivision IS NOT NULL 
                 AND u.Division IS NOT NULL 
                 AND @ApproverDivision = u.Division
                 AND (@ApproverSeniority IS NULL OR u.SeniorityLevel IS NULL OR @ApproverSeniority >= u.SeniorityLevel)
                 AND NOT EXISTS (
                     -- Check if there's any role the approver cannot request (using eligibility logic)
                     SELECT 1 
                     FROM [jit].[Request_Roles] rr2
                     WHERE rr2.RequestId = r.RequestId
                     -- Check if approver CANNOT request this role
                     AND NOT (
                         -- Priority 1: Explicit user override allows
                         EXISTS (
                             SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue
                             WHERE ue.UserId = @ApproverUserId AND ue.RoleId = rr2.RoleId
                             AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= GETUTCDATE())
                             AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= GETUTCDATE())
                             AND ue.CanRequest = 1
                         )
                         -- Priority 2: OR scope rules allow (only if no user override denies)
                         OR (
                             -- User-specific rules
                             EXISTS (
                                 SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                                 WHERE rer.RoleId = rr2.RoleId
                                 AND rer.ScopeType = 'User'
                                 AND rer.ScopeValue = @ApproverUserId
                                 AND rer.CanRequest = 1
                                 AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                                 AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                             )
                             -- Team rules (user must be active member)
                             OR EXISTS (
                                 SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                                 INNER JOIN [jit].[User_Teams] ut ON CAST(ut.TeamId AS NVARCHAR(255)) = rer.ScopeValue
                                 WHERE rer.RoleId = rr2.RoleId
                                 AND rer.ScopeType = 'Team'
                                 AND ut.UserId = @ApproverUserId
                                 AND ut.IsActive = 1
                                 AND rer.CanRequest = 1
                                 AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                                 AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                             )
                             -- Department rules
                             OR EXISTS (
                                 SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                                 WHERE rer.RoleId = rr2.RoleId
                                 AND rer.ScopeType = 'Department'
                                 AND rer.ScopeValue = @ApproverDepartment
                                 AND @ApproverDepartment IS NOT NULL
                                 AND rer.CanRequest = 1
                                 AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                                 AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                             )
                             -- Division rules
                             OR EXISTS (
                                 SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                                 WHERE rer.RoleId = rr2.RoleId
                                 AND rer.ScopeType = 'Division'
                                 AND rer.ScopeValue = @ApproverDivision
                                 AND @ApproverDivision IS NOT NULL
                                 AND rer.CanRequest = 1
                                 AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                                 AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                             )
                             -- All rules (lowest priority)
                             OR EXISTS (
                                 SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                                 WHERE rer.RoleId = rr2.RoleId
                                 AND rer.ScopeType = 'All'
                                 AND rer.ScopeValue IS NULL
                                 AND rer.CanRequest = 1
                                 AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                                 AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                             )
                         )
                         -- Exclude if user has explicit denial override
                         AND NOT EXISTS (
                             SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue2
                             WHERE ue2.UserId = @ApproverUserId AND ue2.RoleId = rr2.RoleId
                             AND (ue2.ValidFromUtc IS NULL OR ue2.ValidFromUtc <= GETUTCDATE())
                             AND (ue2.ValidToUtc IS NULL OR ue2.ValidToUtc >= GETUTCDATE())
                             AND ue2.CanRequest = 0
                         )
                     )
                 ) THEN 'Approver Eligibility Match'
            ELSE 'Unknown'
        END AS ApprovalReason
    FROM [jit].[Requests] r
    INNER JOIN [jit].[Request_Roles] rr ON r.RequestId = rr.RequestId
    INNER JOIN [jit].[Roles] rol ON rr.RoleId = rol.RoleId AND rol.IsActive = 1
    INNER JOIN [jit].[Users] u ON r.UserId = u.UserId
    WHERE r.Status = 'Pending'
    GROUP BY r.RequestId, r.UserId, u.DisplayName, u.LoginName, u.Email, u.Department, u.Division, 
             u.SeniorityLevel, r.RequestedDurationMinutes, r.Justification, r.TicketRef, 
             r.UserDeptSnapshot, r.UserTitleSnapshot, r.CreatedUtc, r.Status
    HAVING 
        -- Admin can approve all requests
        @ApproverIsAdmin = 1
        OR
        -- Data Steward can approve requests from same division
        (
            @ApproverIsDataSteward = 1
            AND @ApproverDivision IS NOT NULL 
            AND u.Division IS NOT NULL 
            AND @ApproverDivision = u.Division
        )
        OR
        -- IsApprover can approve requests where they can request ALL roles AND have higher/equal seniority
        (
            @ApproverIsApprover = 1
            -- Same division
            AND @ApproverDivision IS NOT NULL 
            AND u.Division IS NOT NULL 
            AND @ApproverDivision = u.Division
            -- Approver seniority >= requester seniority
            AND (@ApproverSeniority IS NULL OR u.SeniorityLevel IS NULL OR @ApproverSeniority >= u.SeniorityLevel)
            -- Check that approver can request ALL roles (no role fails the eligibility check)
            AND NOT EXISTS (
                SELECT 1 
                FROM [jit].[Request_Roles] rr2
                WHERE rr2.RequestId = r.RequestId
                -- Check if approver CANNOT request this role (using eligibility logic)
                AND NOT (
                    -- Priority 1: Explicit user override allows
                    EXISTS (
                        SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue
                        WHERE ue.UserId = @ApproverUserId AND ue.RoleId = rr2.RoleId
                        AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= GETUTCDATE())
                        AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= GETUTCDATE())
                        AND ue.CanRequest = 1
                    )
                    -- Priority 2: OR scope rules allow (only if no user override denies)
                    OR (
                        -- User-specific rules
                        EXISTS (
                            SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                            WHERE rer.RoleId = rr2.RoleId
                            AND rer.ScopeType = 'User'
                            AND rer.ScopeValue = @ApproverUserId
                            AND rer.CanRequest = 1
                            AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                            AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                        )
                        -- Team rules (user must be active member)
                        OR EXISTS (
                            SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                            INNER JOIN [jit].[User_Teams] ut ON CAST(ut.TeamId AS NVARCHAR(255)) = rer.ScopeValue
                            WHERE rer.RoleId = rr2.RoleId
                            AND rer.ScopeType = 'Team'
                            AND ut.UserId = @ApproverUserId
                            AND ut.IsActive = 1
                            AND rer.CanRequest = 1
                            AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                            AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                        )
                         -- Department rules
                         OR EXISTS (
                             SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                             WHERE rer.RoleId = rr2.RoleId
                             AND rer.ScopeType = 'Department'
                             AND rer.ScopeValue = @ApproverDepartment
                             AND @ApproverDepartment IS NOT NULL
                             AND rer.CanRequest = 1
                             AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                             AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                         )
                        -- Division rules
                        OR EXISTS (
                            SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                            WHERE rer.RoleId = rr2.RoleId
                            AND rer.ScopeType = 'Division'
                            AND rer.ScopeValue = @ApproverDivision
                            AND @ApproverDivision IS NOT NULL
                            AND rer.CanRequest = 1
                            AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                            AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                        )
                        -- All rules (lowest priority)
                        OR EXISTS (
                            SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                            WHERE rer.RoleId = rr2.RoleId
                            AND rer.ScopeType = 'All'
                            AND rer.ScopeValue IS NULL
                            AND rer.CanRequest = 1
                            AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                            AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                        )
                    )
                    -- Exclude if user has explicit denial override
                    AND NOT EXISTS (
                        SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue2
                        WHERE ue2.UserId = @ApproverUserId AND ue2.RoleId = rr2.RoleId
                        AND (ue2.ValidFromUtc IS NULL OR ue2.ValidFromUtc <= GETUTCDATE())
                        AND (ue2.ValidToUtc IS NULL OR ue2.ValidToUtc >= GETUTCDATE())
                        AND ue2.CanRequest = 0
                    )
                )
            )
        )
    ORDER BY r.CreatedUtc ASC;
END
GO

