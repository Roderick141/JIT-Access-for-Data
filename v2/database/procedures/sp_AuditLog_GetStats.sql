USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_AuditLog_GetStats]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_AuditLog_GetStats]
GO
CREATE PROCEDURE [jit].[sp_AuditLog_GetStats]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EventType, COUNT(*) AS EventCount
    FROM [jit].[AuditLog]
    GROUP BY EventType
    ORDER BY EventCount DESC;
END
GO

