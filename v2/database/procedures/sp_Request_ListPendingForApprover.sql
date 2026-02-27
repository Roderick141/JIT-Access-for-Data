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
        FROM [jit].[vw_User_CurrentContext]
        WHERE UserId = @ApproverUserId
            AND IsEnabled = 1;

    ;WITH RequestEligibility AS (
        SELECT
            r.RequestId,
            CASE
                WHEN @ApproverIsAdmin = 1 THEN 1
                WHEN @ApproverIsDataSteward = 1
                     AND @ApproverDivision IS NOT NULL
                     AND u.Division IS NOT NULL
                     AND @ApproverDivision = u.Division THEN 1
                WHEN @ApproverIsApprover = 1
                     AND @ApproverDivision IS NOT NULL
                     AND u.Division IS NOT NULL
                     AND @ApproverDivision = u.Division
                     AND (@ApproverSeniority IS NULL OR u.SeniorityLevel IS NULL OR @ApproverSeniority >= u.SeniorityLevel)
                     AND NOT EXISTS (
                         SELECT 1
                         FROM [jit].[Request_Roles] rr2
                         WHERE rr2.RequestId = r.RequestId
                           AND NOT (
                               EXISTS (
                                   SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue
                                   WHERE ue.UserId = @ApproverUserId AND ue.RoleId = rr2.RoleId
                                     AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= GETUTCDATE())
                                     AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= GETUTCDATE())
                                     AND ue.CanRequest = 1
                               )
                               OR (
                                   EXISTS (
                                       SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
                                       WHERE rer.RoleId = rr2.RoleId
                                         AND rer.ScopeType = 'User'
                                         AND rer.ScopeValue = @ApproverUserId
                                         AND rer.CanRequest = 1
                                         AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
                                         AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
                                   )
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
                               AND NOT EXISTS (
                                   SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue2
                                   WHERE ue2.UserId = @ApproverUserId AND ue2.RoleId = rr2.RoleId
                                     AND (ue2.ValidFromUtc IS NULL OR ue2.ValidFromUtc <= GETUTCDATE())
                                     AND (ue2.ValidToUtc IS NULL OR ue2.ValidToUtc >= GETUTCDATE())
                                     AND ue2.CanRequest = 0
                               )
                           )
                     ) THEN 1
                ELSE 0
            END AS CanApproveRequest
        FROM [jit].[Requests] r
        INNER JOIN [jit].[vw_User_CurrentContext] u ON r.UserId = u.UserId
        WHERE r.Status = 'Pending'
          AND u.IsEnabled = 1
    )
    
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
            WHEN re.CanApproveRequest = 1 AND @ApproverIsApprover = 1 THEN 'Approver Eligibility Match'
            ELSE 'Unknown'
        END AS ApprovalReason
    FROM [jit].[Requests] r
    INNER JOIN [jit].[Request_Roles] rr ON r.RequestId = rr.RequestId
    INNER JOIN [jit].[Roles] rol ON rr.RoleId = rol.RoleId AND rol.IsActive = 1
    INNER JOIN [jit].[vw_User_CurrentContext] u ON r.UserId = u.UserId
    INNER JOIN RequestEligibility re ON re.RequestId = r.RequestId
    WHERE r.Status = 'Pending'
      AND u.IsEnabled = 1
      AND re.CanApproveRequest = 1
    GROUP BY r.RequestId, r.UserId, u.DisplayName, u.LoginName, u.Email, u.Department, u.Division, 
             u.SeniorityLevel, r.RequestedDurationMinutes, r.Justification, r.TicketRef,
             r.UserDeptSnapshot, r.UserTitleSnapshot, r.CreatedUtc, r.Status, re.CanApproveRequest
    ORDER BY r.CreatedUtc ASC;
END
GO

