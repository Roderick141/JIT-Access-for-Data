USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_LookupValues]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_LookupValues]
GO
CREATE PROCEDURE [jit].[sp_LookupValues]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 'users' AS LookupType, UserId AS LookupValue, DisplayName AS LookupLabel
    FROM [jit].[Users] WHERE IsActive = 1
    UNION ALL
    SELECT 'teams', CAST(TeamId AS NVARCHAR(255)), TeamName
    FROM [jit].[Teams] WHERE IsActive = 1
    UNION ALL
    SELECT 'departments', Department, Department
    FROM [jit].[Users] WHERE Department IS NOT NULL
    UNION ALL
    SELECT 'divisions', Division, Division
    FROM [jit].[Users] WHERE Division IS NOT NULL;
END
GO

