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

    DECLARE @Actor NVARCHAR(255) = ISNULL(@ActorUserId, SUSER_SNAME());
    DECLARE @CurrentUtc DATETIME2 = GETUTCDATE();
    DECLARE @CurrentDivision NVARCHAR(255);
    DECLARE @CurrentDepartment NVARCHAR(255);
    DECLARE @CurrentJobTitle NVARCHAR(255);
    DECLARE @CurrentSeniorityLevel INT;
    DECLARE @CurrentIsEnabled BIT;
    DECLARE @CurrentIsAdmin BIT;
    DECLARE @CurrentIsApprover BIT;
    DECLARE @CurrentIsDataSteward BIT;

    SELECT TOP 1
        @CurrentDivision = c.Division,
        @CurrentDepartment = c.Department,
        @CurrentJobTitle = c.JobTitle,
        @CurrentSeniorityLevel = c.SeniorityLevel,
        @CurrentIsEnabled = c.IsEnabled,
        @CurrentIsAdmin = c.IsAdmin,
        @CurrentIsApprover = c.IsApprover,
        @CurrentIsDataSteward = c.IsDataSteward
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = @UserId
      AND c.IsActive = 1
    ORDER BY c.ValidFromUtc DESC, c.UserContextVersionId DESC;

    IF @CurrentIsAdmin IS NULL
    BEGIN
        INSERT INTO [jit].[User_Context_Versions] (
            UserId,
            Division,
            Department,
            JobTitle,
            SeniorityLevel,
            IsAdmin,
            IsApprover,
            IsDataSteward,
            IsEnabled,
            IsActive,
            ValidFromUtc,
            CreatedBy,
            UpdatedBy
        )
        VALUES (
            @UserId,
            NULL,
            NULL,
            NULL,
            NULL,
            @IsAdmin,
            @IsApprover,
            @IsDataSteward,
            1,
            1,
            @CurrentUtc,
            @Actor,
            @Actor
        );
    END
    ELSE IF @CurrentIsAdmin <> @IsAdmin
         OR @CurrentIsApprover <> @IsApprover
         OR @CurrentIsDataSteward <> @IsDataSteward
    BEGIN
        UPDATE [jit].[User_Context_Versions]
        SET IsActive = 0,
            ValidToUtc = @CurrentUtc,
            UpdatedUtc = @CurrentUtc,
            UpdatedBy = @Actor
        WHERE UserId = @UserId
          AND IsActive = 1;

        INSERT INTO [jit].[User_Context_Versions] (
            UserId,
            Division,
            Department,
            JobTitle,
            SeniorityLevel,
            IsAdmin,
            IsApprover,
            IsDataSteward,
            IsEnabled,
            IsActive,
            ValidFromUtc,
            CreatedBy,
            UpdatedBy
        )
        VALUES (
            @UserId,
            @CurrentDivision,
            @CurrentDepartment,
            @CurrentJobTitle,
            @CurrentSeniorityLevel,
            @IsAdmin,
            @IsApprover,
            @IsDataSteward,
            ISNULL(@CurrentIsEnabled, 1),
            1,
            @CurrentUtc,
            @Actor,
            @Actor
        );
    END

    UPDATE [jit].[Users]
    SET IsAdmin = @IsAdmin,
        IsApprover = @IsApprover,
        IsDataSteward = @IsDataSteward,
        UpdatedUtc = @CurrentUtc,
        UpdatedBy = @Actor
    WHERE UserId = @UserId;
END
GO

