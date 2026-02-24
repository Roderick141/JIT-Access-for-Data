USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Team_ListWithStats]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Team_ListWithStats]
GO
CREATE PROCEDURE [jit].[sp_Team_ListWithStats]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        t.TeamId,
        t.TeamName,
        t.Description AS TeamDescription,
        t.Department,
        t.IsActive,
        COUNT(CASE WHEN ut.IsActive = 1 THEN 1 END) AS MemberCount
    FROM [jit].[Teams] t
    LEFT JOIN [jit].[User_Teams] ut ON ut.TeamId = t.TeamId
    WHERE t.IsActive = 1
    GROUP BY t.TeamId, t.TeamName, t.Description, t.Department, t.IsActive
    ORDER BY t.TeamName;
END
GO

