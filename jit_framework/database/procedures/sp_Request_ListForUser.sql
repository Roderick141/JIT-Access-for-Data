-- =============================================
-- Stored Procedure: jit.sp_Request_ListForUser
-- Returns all requests (history) for a user
-- Used by user portal
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_ListForUser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_ListForUser]
GO

CREATE PROCEDURE [jit].[sp_Request_ListForUser]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        r.RequestId,
        r.UserId,
        rol.RoleName,
        r.RequestedDurationMinutes,
        r.Justification,
        r.TicketRef,
        r.Status,
        r.CreatedUtc,
        r.UpdatedUtc
    FROM [jit].[Requests] r
    INNER JOIN [jit].[Roles] rol ON r.RoleId = rol.RoleId
    WHERE r.UserId = @UserId
    ORDER BY r.CreatedUtc DESC;
END
GO

PRINT 'Stored Procedure [jit].[sp_Request_ListForUser] created successfully'
GO

