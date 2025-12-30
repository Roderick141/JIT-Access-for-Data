-- =============================================
-- Stored Procedure: jit.sp_Request_Create
-- Creates new access request
-- Implements auto-approval logic (pre-approved roles and seniority-based)
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Create]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Create]
GO

CREATE PROCEDURE [jit].[sp_Request_Create]
    @UserId INT,
    @RoleId INT,
    @RequestedDurationMinutes INT,
    @Justification NVARCHAR(MAX),
    @TicketRef NVARCHAR(255) = NULL,
    @RequestId BIGINT OUTPUT,
    @Status NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @CanRequest BIT;
    DECLARE @EligibilityReason NVARCHAR(255);
    DECLARE @RequiresApproval BIT;
    DECLARE @AutoApproveMinSeniority INT;
    DECLARE @UserSeniorityLevel INT;
    DECLARE @UserDept NVARCHAR(255);
    DECLARE @UserTitle NVARCHAR(255);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check eligibility
        EXEC [jit].[sp_User_Eligibility_Check] 
            @UserId = @UserId,
            @RoleId = @RoleId,
            @CanRequest = @CanRequest OUTPUT,
            @EligibilityReason = @EligibilityReason OUTPUT;
        
        IF @CanRequest = 0
        BEGIN
            THROW 50001, 'User is not eligible to request this role', 1;
        END
        
        -- Get role details
        SELECT 
            @RequiresApproval = RequiresApproval,
            @AutoApproveMinSeniority = AutoApproveMinSeniority
        FROM [jit].[Roles]
        WHERE RoleId = @RoleId AND IsEnabled = 1;
        
        IF @RequiresApproval IS NULL
        BEGIN
            THROW 50002, 'Role not found or is disabled', 1;
        END
        
        -- Get user details for snapshot
        SELECT 
            @UserSeniorityLevel = SeniorityLevel,
            @UserDept = Department,
            @UserTitle = JobTitle
        FROM [jit].[Users]
        WHERE UserId = @UserId;
        
        -- Determine if auto-approval applies
        DECLARE @AutoApprove BIT = 0;
        DECLARE @AutoApproveReason NVARCHAR(100) = NULL;
        
        -- Tier 1: Pre-approved role
        IF @RequiresApproval = 0
        BEGIN
            SET @AutoApprove = 1;
            SET @AutoApproveReason = 'PreApprovedRole';
            SET @Status = 'AutoApproved';
        END
        -- Tier 2: Seniority-based auto-approval
        ELSE IF @RequiresApproval = 1 AND @AutoApproveMinSeniority IS NOT NULL
        BEGIN
            IF @UserSeniorityLevel IS NOT NULL AND @UserSeniorityLevel >= @AutoApproveMinSeniority
            BEGIN
                SET @AutoApprove = 1;
                SET @AutoApproveReason = 'SeniorityBypass';
                SET @Status = 'AutoApproved';
            END
            ELSE
            BEGIN
                SET @Status = 'Pending';
            END
        END
        -- Tier 3: Manual approval required
        ELSE
        BEGIN
            SET @Status = 'Pending';
        END
        
        -- Create request
        INSERT INTO [jit].[Requests] (
            UserId, RoleId, RequestedDurationMinutes, Justification, TicketRef,
            Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
        )
        VALUES (
            @UserId, @RoleId, @RequestedDurationMinutes, @Justification, @TicketRef,
            @Status, @UserDept, @UserTitle, @CurrentUser
        );
        
        SET @RequestId = SCOPE_IDENTITY();
        
        -- Log audit
        DECLARE @DetailsJson NVARCHAR(MAX) = 
            '{"RoleId":' + CAST(@RoleId AS NVARCHAR(10)) + 
            ',"Status":"' + @Status + '"';
        IF @AutoApproveReason IS NOT NULL
            SET @DetailsJson = @DetailsJson + ',"AutoApproveReason":"' + @AutoApproveReason + '"';
        SET @DetailsJson = @DetailsJson + '}';
        
        INSERT INTO [jit].[AuditLog] (EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, DetailsJson)
        VALUES ('RequestCreated', @UserId, @CurrentUser, @UserId, @RequestId, @DetailsJson);
        
        -- If auto-approved, create grant immediately
        IF @AutoApprove = 1
        BEGIN
            DECLARE @GrantId BIGINT;
            DECLARE @GrantValidFromUtc DATETIME2 = GETUTCDATE();
            DECLARE @GrantValidToUtc DATETIME2 = DATEADD(MINUTE, @RequestedDurationMinutes, GETUTCDATE());
            
            EXEC [jit].[sp_Grant_Issue]
                @RequestId = @RequestId,
                @UserId = @UserId,
                @RoleId = @RoleId,
                @ValidFromUtc = @GrantValidFromUtc,
                @ValidToUtc = @GrantValidToUtc,
                @IssuedByUserId = @UserId,
                @GrantId = @GrantId OUTPUT;
        END
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

PRINT 'Stored Procedure [jit].[sp_Request_Create] created successfully'
GO

