USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Team_Create]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Team_Create]
GO
CREATE PROCEDURE [jit].[sp_Team_Create]
    @TeamName NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @Department NVARCHAR(255) = NULL,
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [jit].[Teams] (TeamName, Description, Department, IsActive, CreatedBy, UpdatedBy)
    VALUES (@TeamName, @Description, @Department, 1, ISNULL(@ActorUserId, SUSER_SNAME()), ISNULL(@ActorUserId, SUSER_SNAME()));
END
GO

