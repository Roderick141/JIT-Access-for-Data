USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Role_SetDbRoles]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Role_SetDbRoles]
GO
CREATE PROCEDURE [jit].[sp_Role_SetDbRoles]
    @RoleId INT,
    @DbRoleIdsCsv NVARCHAR(MAX),
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM STRING_SPLIT(ISNULL(@DbRoleIdsCsv, ''), ',')
        WHERE LTRIM(RTRIM(value)) <> ''
          AND TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NULL
    )
    BEGIN
        THROW 50020, 'Invalid DB role ID list. Only comma-separated integers are allowed.', 1;
    END;

    UPDATE [jit].[Role_To_DB_Roles]
    SET IsActive = 0, ValidToUtc = GETUTCDATE()
    WHERE RoleId = @RoleId AND IsActive = 1;

    INSERT INTO [jit].[Role_To_DB_Roles] (RoleId, DbRoleId, IsRequired, IsActive, ValidFromUtc)
    SELECT @RoleId, TRY_CONVERT(INT, LTRIM(RTRIM(value))), 1, 1, GETUTCDATE()
    FROM STRING_SPLIT(ISNULL(@DbRoleIdsCsv, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> '';
END
GO

