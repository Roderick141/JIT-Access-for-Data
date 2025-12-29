-- =============================================
-- Stored Procedure: jit.sp_User_ResolveCurrentUser
-- Resolves ORIGINAL_LOGIN() to UserId
-- Creates user record if not exists
-- Returns UserId and user metadata
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_User_ResolveCurrentUser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_User_ResolveCurrentUser]
GO

CREATE PROCEDURE [jit].[sp_User_ResolveCurrentUser]
    @UserId INT OUTPUT,
    @LoginName NVARCHAR(255) OUTPUT,
    @DisplayName NVARCHAR(255) OUTPUT,
    @Department NVARCHAR(255) OUTPUT,
    @Division NVARCHAR(255) OUTPUT,
    @JobTitle NVARCHAR(255) OUTPUT,
    @SeniorityLevel INT OUTPUT,
    @IsActive BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentLogin NVARCHAR(255) = ORIGINAL_LOGIN();
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    
    -- Try to find existing user
    SELECT 
        @UserId = UserId,
        @LoginName = LoginName,
        @DisplayName = DisplayName,
        @Department = Department,
        @Division = Division,
        @JobTitle = JobTitle,
        @SeniorityLevel = SeniorityLevel,
        @IsActive = IsActive
    FROM [jit].[Users]
    WHERE LoginName = @CurrentLogin;
    
    -- If user doesn't exist, create a basic record
    IF @UserId IS NULL
    BEGIN
        INSERT INTO [jit].[Users] (
            LoginName,
            DisplayName,
            CreatedBy,
            UpdatedBy
        )
        VALUES (
            @CurrentLogin,
            @CurrentUser,
            @CurrentUser,
            @CurrentUser
        );
        
        SET @UserId = SCOPE_IDENTITY();
        SET @LoginName = @CurrentLogin;
        SET @DisplayName = @CurrentUser;
        SET @Department = NULL;
        SET @Division = NULL;
        SET @JobTitle = NULL;
        SET @SeniorityLevel = NULL;
        SET @IsActive = 1;
        
        -- Log the creation
        INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, TargetUserId, DetailsJson)
        VALUES ('UserCreated', @CurrentUser, @UserId, 
            '{"LoginName":"' + @CurrentLogin + '","Source":"AutoCreated"}');
    END
END
GO

PRINT 'Stored Procedure [jit].[sp_User_ResolveCurrentUser] created successfully'
GO

