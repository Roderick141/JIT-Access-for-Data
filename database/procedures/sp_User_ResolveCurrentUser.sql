-- =============================================
-- Stored Procedure: jit.sp_User_ResolveCurrentUser
-- Resolves ORIGINAL_LOGIN() to UserId
-- User must exist (no auto-creation)
-- Returns UserId and user metadata
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_User_ResolveCurrentUser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_User_ResolveCurrentUser]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_User_ResolveCurrentUser]
    @UserId NVARCHAR(255) OUTPUT,
    @LoginName NVARCHAR(255) OUTPUT,
    @DisplayName NVARCHAR(255) OUTPUT,
    @Department NVARCHAR(255) OUTPUT,
    @Division NVARCHAR(255) OUTPUT,
    @JobTitle NVARCHAR(255) OUTPUT,
    @SeniorityLevel INT OUTPUT,
    @IsAdmin BIT OUTPUT,
    @IsActive BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentLogin NVARCHAR(255) = ORIGINAL_LOGIN();
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    
    -- Find existing user (user must exist - no auto-creation)
    SELECT 
        @UserId = UserId,
        @LoginName = LoginName,
        @DisplayName = DisplayName,
        @Department = Department,
        @Division = Division,
        @JobTitle = JobTitle,
        @SeniorityLevel = SeniorityLevel,
        @IsAdmin = IsAdmin,
        @IsActive = IsActive
    FROM [jit].[Users]
    WHERE LoginName = @CurrentLogin
    AND IsActive = 1;
    
    -- If user doesn't exist, return NULL values (user must be created manually or via AD sync)
    IF @UserId IS NULL
    BEGIN
        SET @UserId = NULL;
        SET @LoginName = @CurrentLogin;
        SET @DisplayName = @CurrentUser;
        SET @Department = NULL;
        SET @Division = NULL;
        SET @JobTitle = NULL;
        SET @SeniorityLevel = NULL;
        SET @IsAdmin = 0;
        SET @IsActive = 0;
    END
END
GO

