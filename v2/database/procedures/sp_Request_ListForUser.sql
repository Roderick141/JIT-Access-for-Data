-- =============================================
-- Stored Procedure: jit.sp_Request_ListForUser
-- Returns all requests (history) for a user
-- Used by user portal
-- Now supports multiple roles per request
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_ListForUser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_ListForUser]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Request_ListForUser]
    @UserId NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        r.RequestId,
        r.UserId,
        roleAgg.RoleNames,
        roleAgg.RoleCount,
        r.RequestedDurationMinutes,
        r.Justification,
        r.TicketRef,
        r.Status,
        r.CreatedUtc,
        r.UpdatedUtc,
        a.DecisionComment,
        a.DecisionUtc,
        approver.DisplayName AS ApproverName,
        g.RevokedUtc,
        g.RevokeReason
    FROM [jit].[Requests] r
    OUTER APPLY (
        SELECT
            STRING_AGG(roleRows.RoleName, ', ') AS RoleNames,
            COUNT(*) AS RoleCount
        FROM (
            SELECT DISTINCT
                rr.RoleId,
                rol.RoleName
            FROM [jit].[Request_Roles] rr
            INNER JOIN [jit].[Roles] rol
                ON rr.RoleId = rol.RoleId
               AND rol.IsActive = 1
            WHERE rr.RequestId = r.RequestId
        ) roleRows
    ) roleAgg
    OUTER APPLY (
        SELECT TOP 1
            ap.ApproverUserId,
            ap.DecisionComment,
            ap.DecisionUtc
        FROM [jit].[Approvals] ap
        WHERE ap.RequestId = r.RequestId
        ORDER BY ap.DecisionUtc DESC, ap.ApprovalId DESC
    ) a
    LEFT JOIN [jit].[vw_User_CurrentContext] approver ON approver.UserId = a.ApproverUserId
    OUTER APPLY (
        SELECT TOP 1
            gr.RevokedUtc,
            gr.RevokeReason
        FROM [jit].[Grants] gr
        WHERE gr.RequestId = r.RequestId
        ORDER BY
            CASE WHEN gr.RevokedUtc IS NULL THEN 1 ELSE 0 END,
            gr.RevokedUtc DESC,
            gr.GrantId DESC
    ) g
    WHERE r.UserId = @UserId
    ORDER BY r.CreatedUtc DESC;
END
GO

