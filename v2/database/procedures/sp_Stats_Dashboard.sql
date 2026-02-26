USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Stats_Dashboard]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Stats_Dashboard]
GO
CREATE PROCEDURE [jit].[sp_Stats_Dashboard]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
      (SELECT COUNT(*) FROM [jit].[Roles] WHERE IsActive = 1) AS totalRoles,
      (SELECT COUNT(*) FROM [jit].[Roles] WHERE IsActive = 1 AND SensitivityLevel = 'Sensitive') AS sensitiveRoles,
      (SELECT COUNT(*) FROM [jit].[Grants] WHERE Status = 'Active') AS activeGrants,
      (SELECT COUNT(*) FROM [jit].[vw_User_CurrentContext] WHERE IsEnabled = 1) AS totalUsers;
END
GO

