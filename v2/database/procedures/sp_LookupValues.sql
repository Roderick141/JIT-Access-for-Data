USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_LookupValues]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_LookupValues]
GO
CREATE PROCEDURE [jit].[sp_LookupValues]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 'users' AS LookupType, UserId AS LookupValue, DisplayName AS LookupLabel
    FROM [jit].[vw_User_CurrentContext] WHERE IsEnabled = 1
    UNION ALL
    SELECT 'teams', CAST(TeamId AS NVARCHAR(255)), TeamName
    FROM [jit].[Teams] WHERE IsActive = 1
    UNION ALL
    SELECT 'departments', Department, Department
    FROM [jit].[vw_User_CurrentContext] WHERE Department IS NOT NULL AND IsEnabled = 1
    UNION ALL
    SELECT 'divisions', Division, Division
    FROM [jit].[vw_User_CurrentContext] WHERE Division IS NOT NULL AND IsEnabled = 1;
END
GO

