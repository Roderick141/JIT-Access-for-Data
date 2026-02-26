USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Team_GetMembers]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Team_GetMembers]
GO
CREATE PROCEDURE [jit].[sp_Team_GetMembers]
    @TeamId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.DisplayName, u.Email
    FROM [jit].[User_Teams] ut
        INNER JOIN [jit].[vw_User_CurrentContext] u ON u.UserId = ut.UserId
    WHERE ut.TeamId = @TeamId
            AND ut.IsActive = 1
            AND u.IsEnabled = 1;
END
GO

