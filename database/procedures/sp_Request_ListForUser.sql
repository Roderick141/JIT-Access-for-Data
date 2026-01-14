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
        STRING_AGG(rol.RoleName, ', ') AS RoleNames,
        COUNT(rr.RoleId) AS RoleCount,
        r.RequestedDurationMinutes,
        r.Justification,
        r.TicketRef,
        r.Status,
        r.CreatedUtc,
        r.UpdatedUtc,
        a.DecisionComment AS ApproverComment
    FROM [jit].[Requests] r
    INNER JOIN [jit].[Request_Roles] rr ON r.RequestId = rr.RequestId
    INNER JOIN [jit].[Roles] rol ON rr.RoleId = rol.RoleId
    LEFT JOIN [jit].[Approvals] a ON r.RequestId = a.RequestId
    WHERE r.UserId = @UserId
    GROUP BY r.RequestId, r.UserId, r.RequestedDurationMinutes, r.Justification, r.TicketRef, r.Status, r.CreatedUtc, r.UpdatedUtc, a.DecisionComment
    ORDER BY r.CreatedUtc DESC;
END
GO

