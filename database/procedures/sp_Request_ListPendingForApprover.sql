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
    @ApproverUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ApproverDivision NVARCHAR(255);
    DECLARE @ApproverSeniority INT;
    DECLARE @ApproverIsAdmin BIT;
    DECLARE @CanApprove BIT;
    DECLARE @ApprovalReason NVARCHAR(100);
    
    -- Get approver details once
    SELECT 
        @ApproverDivision = Division,
        @ApproverSeniority = SeniorityLevel,
        @ApproverIsAdmin = IsAdmin
    FROM [jit].[Users]
    WHERE UserId = @ApproverUserId;
    
    -- Get requests where approver can approve ALL roles
    SELECT DISTINCT
        r.RequestId,
        r.UserId,
        u.DisplayName AS RequesterName,
        u.LoginName AS RequesterLoginName,
        u.Department AS RequesterDepartment,
        u.Division AS RequesterDivision,
        u.SeniorityLevel AS RequesterSeniority,
        STRING_AGG(rol.RoleName, ', ') AS RoleNames,
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
            WHEN @ApproverDivision IS NOT NULL 
                 AND u.Division IS NOT NULL 
                 AND @ApproverDivision = u.Division
                 AND NOT EXISTS (
                     -- Check if there's any role the approver cannot approve
                     SELECT 1 
                     FROM [jit].[Request_Roles] rr2
                     INNER JOIN [jit].[Roles] rol2 ON rr2.RoleId = rol2.RoleId
                     WHERE rr2.RequestId = r.RequestId
                     AND (
                         rol2.AutoApproveMinSeniority IS NULL
                         OR @ApproverSeniority IS NULL
                         OR @ApproverSeniority < rol2.AutoApproveMinSeniority
                         OR u.SeniorityLevel IS NULL
                         OR u.SeniorityLevel >= @ApproverSeniority
                     )
                 ) THEN 'Division + Seniority Match'
            ELSE 'Unknown'
        END AS ApprovalReason
    FROM [jit].[Requests] r
    INNER JOIN [jit].[Request_Roles] rr ON r.RequestId = rr.RequestId
    INNER JOIN [jit].[Roles] rol ON rr.RoleId = rol.RoleId
    INNER JOIN [jit].[Users] u ON r.UserId = u.UserId
    WHERE r.Status = 'Pending'
    GROUP BY r.RequestId, r.UserId, u.DisplayName, u.LoginName, u.Department, u.Division, 
             u.SeniorityLevel, r.RequestedDurationMinutes, r.Justification, r.TicketRef, 
             r.UserDeptSnapshot, r.UserTitleSnapshot, r.CreatedUtc, r.Status
    HAVING 
        -- Admin can approve all requests
        @ApproverIsAdmin = 1
        OR
        -- Approver can approve ALL roles in the request
        (
            -- Same division
            @ApproverDivision IS NOT NULL 
            AND u.Division IS NOT NULL 
            AND @ApproverDivision = u.Division
            -- Check that approver can approve ALL roles (no role fails the check)
            AND NOT EXISTS (
                SELECT 1 
                FROM [jit].[Request_Roles] rr2
                INNER JOIN [jit].[Roles] rol2 ON rr2.RoleId = rol2.RoleId
                WHERE rr2.RequestId = r.RequestId
                AND (
                    -- Role has no auto-approve seniority requirement (would need manual check, skip for now)
                    rol2.AutoApproveMinSeniority IS NULL
                    -- Approver doesn't have seniority set
                    OR @ApproverSeniority IS NULL
                    -- Approver's seniority is less than required
                    OR @ApproverSeniority < rol2.AutoApproveMinSeniority
                    -- Requester's seniority is equal or higher than approver (cannot approve)
                    OR u.SeniorityLevel IS NULL
                    OR u.SeniorityLevel >= @ApproverSeniority
                )
            )
        )
    ORDER BY r.CreatedUtc ASC;
END
GO

