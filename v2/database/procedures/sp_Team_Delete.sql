USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_Team_Delete]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_Team_Delete]
GO
CREATE PROCEDURE [jit].[sp_Team_Delete]
    @TeamId INT,
    @ActorUserId NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [jit].[Teams]
    SET IsActive = 0, UpdatedUtc = GETUTCDATE(), UpdatedBy = ISNULL(@ActorUserId, SUSER_SNAME())
    WHERE TeamId = @TeamId;
END
GO

