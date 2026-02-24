-- =============================================
-- Stored Procedure: jit.sp_Request_GetRoles
-- Returns all roles associated with a request
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_GetRoles]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_GetRoles]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Request_GetRoles]
    @RequestId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        r.RoleId,
        r.RoleName,
        r.Description,
        r.SensitivityLevel,
        r.IconName,
        r.IconColor,
        rr.CreatedUtc AS AssociatedUtc
    FROM [jit].[Request_Roles] rr
    INNER JOIN [jit].[Roles] r ON rr.RoleId = r.RoleId AND r.IsActive = 1
    WHERE rr.RequestId = @RequestId
    ORDER BY r.RoleName;
END
GO
