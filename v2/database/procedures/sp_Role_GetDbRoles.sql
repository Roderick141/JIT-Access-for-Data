USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Role_GetDbRoles]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Role_GetDbRoles]
GO
CREATE PROCEDURE [jit].[sp_Role_GetDbRoles]
    @RoleId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT dbr.*
    FROM [jit].[Role_To_DB_Roles] map
    INNER JOIN [jit].[DB_Roles] dbr ON dbr.DbRoleId = map.DbRoleId
    WHERE map.RoleId = @RoleId AND map.IsActive = 1;
END
GO

