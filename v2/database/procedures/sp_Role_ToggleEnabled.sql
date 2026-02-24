USE [DMAP_JIT_Permissions]
GO

IF OBJECT_ID(N'[jit].[sp_Role_ToggleEnabled]', N'P') IS NOT NULL
    DROP PROCEDURE [jit].[sp_Role_ToggleEnabled]
GO

CREATE PROCEDURE [jit].[sp_Role_ToggleEnabled]
    @RoleId INT,
    @IsEnabled BIT,
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [jit].[Roles]
    SET IsEnabled = @IsEnabled, UpdatedUtc = GETUTCDATE(), UpdatedBy = ISNULL(@ActorUserId, SUSER_SNAME())
    WHERE RoleId = @RoleId AND IsActive = 1;
END
GO

