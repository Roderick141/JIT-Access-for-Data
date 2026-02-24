USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_User_UpdateSystemRoles]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_User_UpdateSystemRoles]
GO
CREATE PROCEDURE [jit].[sp_User_UpdateSystemRoles]
    @UserId NVARCHAR(255),
    @IsAdmin BIT,
    @IsApprover BIT,
    @IsDataSteward BIT,
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [jit].[Users]
    SET IsAdmin = @IsAdmin,
        IsApprover = @IsApprover,
        IsDataSteward = @IsDataSteward,
        UpdatedUtc = GETUTCDATE(),
        UpdatedBy = ISNULL(@ActorUserId, SUSER_SNAME())
    WHERE UserId = @UserId;
END
GO

