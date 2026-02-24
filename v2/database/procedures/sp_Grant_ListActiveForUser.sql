-- =============================================
-- Stored Procedure: jit.sp_Grant_ListActiveForUser
-- Returns active grants for user
-- Used by user portal
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Grant_ListActiveForUser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Grant_ListActiveForUser]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Grant_ListActiveForUser]
    @UserId NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        g.GrantId,
        g.RequestId,
        g.UserId,
        g.RoleId,
        r.RoleName,
        r.Description AS RoleDescription,
        r.SensitivityLevel,
        g.ValidFromUtc AS GrantedUtc,
        g.ValidToUtc AS ExpiryUtc,
        g.Status
    FROM [jit].[Grants] g
    INNER JOIN [jit].[Roles] r ON r.RoleId = g.RoleId AND r.IsActive = 1
    WHERE g.UserId = @UserId
    AND g.Status = 'Active'
    ORDER BY g.ValidToUtc ASC;
END
GO
