USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Team_SetMembers]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Team_SetMembers]
GO
CREATE PROCEDURE [jit].[sp_Team_SetMembers]
    @TeamId INT,
    @UserIdsCsv NVARCHAR(MAX),
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM STRING_SPLIT(ISNULL(@UserIdsCsv, ''), ',')
        WHERE LTRIM(RTRIM(value)) <> ''
          AND PATINDEX('%[^A-Za-z0-9._-]%', LTRIM(RTRIM(value))) > 0
    )
    BEGIN
        THROW 50021, 'Invalid user ID list. Only comma-separated user IDs with A-Z, 0-9, dot, underscore, and dash are allowed.', 1;
    END;

    UPDATE [jit].[User_Teams]
    SET IsActive = 0, ValidToUtc = GETUTCDATE()
    WHERE TeamId = @TeamId AND IsActive = 1;

    INSERT INTO [jit].[User_Teams] (UserId, TeamId, IsActive, ValidFromUtc)
    SELECT LTRIM(RTRIM(value)), @TeamId, 1, GETUTCDATE()
    FROM STRING_SPLIT(ISNULL(@UserIdsCsv, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> '';
END
GO

