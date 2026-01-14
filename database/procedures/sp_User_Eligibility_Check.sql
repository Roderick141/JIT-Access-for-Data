-- =============================================
-- Stored Procedure: jit.sp_User_Eligibility_Check
-- Core eligibility resolution logic
-- Checks if user can request a specific role
-- Priority: User_To_Role_Eligibility > Role_Eligibility_Rules (by priority)
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_User_Eligibility_Check]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_User_Eligibility_Check]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_User_Eligibility_Check]
    @UserId NVARCHAR(255),
    @RoleId INT,
    @CanRequest BIT OUTPUT,
    @EligibilityReason NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserDivision NVARCHAR(255);
    DECLARE @UserDepartment NVARCHAR(255);
    DECLARE @CurrentDate DATETIME2 = GETUTCDATE();
    
    -- Get user's division and department
    SELECT 
        @UserDivision = Division,
        @UserDepartment = Department
    FROM [jit].[Users]
    WHERE UserId = @UserId;
    
    -- Priority 1: Check explicit user overrides (highest priority)
    IF EXISTS (
        SELECT 1 FROM [jit].[User_To_Role_Eligibility]
        WHERE UserId = @UserId 
        AND RoleId = @RoleId
        AND (ValidFromUtc IS NULL OR ValidFromUtc <= @CurrentDate)
        AND (ValidToUtc IS NULL OR ValidToUtc >= @CurrentDate)
    )
    BEGIN
        SELECT @CanRequest = CanRequest
        FROM [jit].[User_To_Role_Eligibility]
        WHERE UserId = @UserId 
        AND RoleId = @RoleId
        AND (ValidFromUtc IS NULL OR ValidFromUtc <= @CurrentDate)
        AND (ValidToUtc IS NULL OR ValidToUtc >= @CurrentDate);
        
        SET @EligibilityReason = CASE WHEN @CanRequest = 1 THEN 'ExplicitUserOverride_Allow' ELSE 'ExplicitUserOverride_Deny' END;
        RETURN;
    END
    
    -- Priority 2: Check scope-based eligibility rules (by priority)
    DECLARE @BestPriority INT = -1;
    DECLARE @BestCanRequest BIT = 0;
    DECLARE @BestReason NVARCHAR(255) = 'NoEligibilityRule';
    
    -- Check User-specific rules
    DECLARE @UserRulePriority INT;
    DECLARE @UserRuleCanRequest BIT;
    
    SELECT TOP 1
        @UserRulePriority = Priority,
        @UserRuleCanRequest = CanRequest
    FROM [jit].[Role_Eligibility_Rules]
    WHERE RoleId = @RoleId
    AND ScopeType = 'User'
    AND ScopeValue = @UserId
    AND (ValidFromUtc IS NULL OR ValidFromUtc <= @CurrentDate)
    AND (ValidToUtc IS NULL OR ValidToUtc >= @CurrentDate)
    ORDER BY Priority DESC;
    
    IF @UserRulePriority > @BestPriority
    BEGIN
        SET @BestPriority = @UserRulePriority;
        SET @BestCanRequest = @UserRuleCanRequest;
        SET @BestReason = 'UserScopeRule';
    END
    
    -- Check Team rules (user must be active member)
    DECLARE @TeamRulePriority INT;
    DECLARE @TeamRuleCanRequest BIT;
    
    SELECT TOP 1
        @TeamRulePriority = rer.Priority,
        @TeamRuleCanRequest = rer.CanRequest
    FROM [jit].[Role_Eligibility_Rules] rer
    INNER JOIN [jit].[User_Teams] ut ON CAST(ut.TeamId AS NVARCHAR(255)) = rer.ScopeValue
    WHERE rer.RoleId = @RoleId
    AND rer.ScopeType = 'Team'
    AND ut.UserId = @UserId
    AND ut.IsActive = 1
    AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentDate)
    AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentDate)
    ORDER BY rer.Priority DESC;
    
    IF @TeamRulePriority > @BestPriority
    BEGIN
        SET @BestPriority = @TeamRulePriority;
        SET @BestCanRequest = @TeamRuleCanRequest;
        SET @BestReason = 'TeamScopeRule';
    END
    
    -- Check Department rules
    DECLARE @DeptRulePriority INT;
    DECLARE @DeptRuleCanRequest BIT;
    
    SELECT TOP 1
        @DeptRulePriority = Priority,
        @DeptRuleCanRequest = CanRequest
    FROM [jit].[Role_Eligibility_Rules]
    WHERE RoleId = @RoleId
    AND ScopeType = 'Department'
    AND ScopeValue = @UserDepartment
    AND (ValidFromUtc IS NULL OR ValidFromUtc <= @CurrentDate)
    AND (ValidToUtc IS NULL OR ValidToUtc >= @CurrentDate)
    ORDER BY Priority DESC;
    
    IF @DeptRulePriority > @BestPriority
    BEGIN
        SET @BestPriority = @DeptRulePriority;
        SET @BestCanRequest = @DeptRuleCanRequest;
        SET @BestReason = 'DepartmentScopeRule';
    END
    
    -- Check Division rules
    DECLARE @DivRulePriority INT;
    DECLARE @DivRuleCanRequest BIT;
    
    SELECT TOP 1
        @DivRulePriority = Priority,
        @DivRuleCanRequest = CanRequest
    FROM [jit].[Role_Eligibility_Rules]
    WHERE RoleId = @RoleId
    AND ScopeType = 'Division'
    AND ScopeValue = @UserDivision
    AND (ValidFromUtc IS NULL OR ValidFromUtc <= @CurrentDate)
    AND (ValidToUtc IS NULL OR ValidToUtc >= @CurrentDate)
    ORDER BY Priority DESC;
    
    IF @DivRulePriority > @BestPriority
    BEGIN
        SET @BestPriority = @DivRulePriority;
        SET @BestCanRequest = @DivRuleCanRequest;
        SET @BestReason = 'DivisionScopeRule';
    END
    
    -- Check 'All' rules (lowest priority for specific rules, but still checked)
    DECLARE @AllRulePriority INT;
    DECLARE @AllRuleCanRequest BIT;
    
    SELECT TOP 1
        @AllRulePriority = Priority,
        @AllRuleCanRequest = CanRequest
    FROM [jit].[Role_Eligibility_Rules]
    WHERE RoleId = @RoleId
    AND ScopeType = 'All'
    AND ScopeValue IS NULL
    AND (ValidFromUtc IS NULL OR ValidFromUtc <= @CurrentDate)
    AND (ValidToUtc IS NULL OR ValidToUtc >= @CurrentDate)
    ORDER BY Priority DESC;
    
    IF @AllRulePriority > @BestPriority
    BEGIN
        SET @BestPriority = @AllRulePriority;
        SET @BestCanRequest = @AllRuleCanRequest;
        SET @BestReason = 'AllScopeRule';
    END
    
    -- Set result
    IF @BestPriority >= 0
    BEGIN
        SET @CanRequest = @BestCanRequest;
        SET @EligibilityReason = @BestReason;
    END
    ELSE
    BEGIN
        SET @CanRequest = 0;
        SET @EligibilityReason = 'NoEligibilityRule';
    END
END
GO

