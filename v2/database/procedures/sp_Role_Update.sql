USE [DMAP_JIT_Permissions]
GO

IF OBJECT_ID(N'[jit].[sp_Role_Update]', N'P') IS NOT NULL
    DROP PROCEDURE [jit].[sp_Role_Update]
GO

CREATE PROCEDURE [jit].[sp_Role_Update]
    @RoleId INT,
    @RoleName NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @SensitivityLevel NVARCHAR(50) = 'Standard',
    @IconName NVARCHAR(100) = 'Database',
    @IconColor NVARCHAR(100) = 'bg-blue-500',
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [jit].[Roles]
    SET IsActive = 0, ValidToUtc = GETUTCDATE(), UpdatedUtc = GETUTCDATE(), UpdatedBy = ISNULL(@ActorUserId, SUSER_SNAME())
    WHERE RoleId = @RoleId AND IsActive = 1;

    INSERT INTO [jit].[Roles] (
        RoleId, RoleName, Description, SensitivityLevel, IconName, IconColor,
        IsEnabled, IsActive, ValidFromUtc, CreatedBy, UpdatedBy
    )
    SELECT
        @RoleId, @RoleName, @Description, @SensitivityLevel, @IconName, @IconColor,
        1, 1, GETUTCDATE(), ISNULL(@ActorUserId, SUSER_SNAME()), ISNULL(@ActorUserId, SUSER_SNAME());
END
GO
