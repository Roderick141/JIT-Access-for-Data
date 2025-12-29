-- =============================================
-- Stored Procedure: jit.sp_Request_ListPendingForApprover
-- Returns pending requests for a specific approver
-- Used by approver portal
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_ListPendingForApprover]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_ListPendingForApprover]
GO

CREATE PROCEDURE [jit].[sp_Request_ListPendingForApprover]
    @ApproverUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get requests that need approval for roles this user can approve
    SELECT DISTINCT
        r.RequestId,
        r.UserId,
        u.DisplayName AS RequesterName,
        u.Department AS RequesterDepartment,
        rol.RoleName,
        r.RequestedDurationMinutes,
        r.Justification,
        r.TicketRef,
        r.UserDeptSnapshot,
        r.UserTitleSnapshot,
        r.CreatedUtc,
        r.Status
    FROM [jit].[Requests] r
    INNER JOIN [jit].[Roles] rol ON r.RoleId = rol.RoleId
    INNER JOIN [jit].[Users] u ON r.UserId = u.UserId
    INNER JOIN [jit].[Role_Approvers] ra ON rol.RoleId = ra.RoleId
    WHERE r.Status = 'Pending'
    AND (
        ra.ApproverUserId = @ApproverUserId
        OR ra.ApproverLoginName = (SELECT LoginName FROM [jit].[Users] WHERE UserId = @ApproverUserId)
    )
    ORDER BY r.CreatedUtc ASC;
END
GO

PRINT 'Stored Procedure [jit].[sp_Request_ListPendingForApprover] created successfully'
GO

