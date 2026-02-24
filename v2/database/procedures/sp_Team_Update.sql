USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Team_Update]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Team_Update]
GO
CREATE PROCEDURE [jit].[sp_Team_Update]
    @TeamId INT,
    @TeamName NVARCHAR(255) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @Department NVARCHAR(255) = NULL,
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [jit].[Teams]
    SET TeamName = COALESCE(@TeamName, TeamName),
        Description = COALESCE(@Description, Description),
        Department = COALESCE(@Department, Department),
        UpdatedUtc = GETUTCDATE(),
        UpdatedBy = ISNULL(@ActorUserId, SUSER_SNAME())
    WHERE TeamId = @TeamId;
END
GO

