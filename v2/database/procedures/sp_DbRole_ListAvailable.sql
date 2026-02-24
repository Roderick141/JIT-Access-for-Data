USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_DbRole_ListAvailable]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_DbRole_ListAvailable]
GO
CREATE PROCEDURE [jit].[sp_DbRole_ListAvailable]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [jit].[DB_Roles] ORDER BY DatabaseName, DbRoleName;
END
GO

