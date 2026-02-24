USE [DMAP_JIT_Permissions]
GO

IF OBJECT_ID(N'[jit].[sp_Role_Create]', N'P') IS NOT NULL
    DROP PROCEDURE [jit].[sp_Role_Create]
GO

CREATE PROCEDURE [jit].[sp_Role_Create]
    @RoleName NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @SensitivityLevel NVARCHAR(50) = 'Standard',
    @IconName NVARCHAR(100) = 'Database',
    @IconColor NVARCHAR(100) = 'bg-blue-500',
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NextRoleId INT = ISNULL((SELECT MAX(RoleId) FROM [jit].[Roles]), 0) + 1;

    INSERT INTO [jit].[Roles] (
        RoleId, RoleName, Description, SensitivityLevel, IconName, IconColor,
        IsEnabled, IsActive, ValidFromUtc, CreatedBy, UpdatedBy
    )
    VALUES (
        @NextRoleId, @RoleName, @Description, @SensitivityLevel, @IconName, @IconColor,
        1, 1, GETUTCDATE(), ISNULL(@ActorUserId, SUSER_SNAME()), ISNULL(@ActorUserId, SUSER_SNAME())
    );
END
GO
