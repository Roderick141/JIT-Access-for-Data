-- =============================================
-- Stored Procedure: jit.sp_Approver_CanApproveRequest
-- Checks if an approver can approve a specific request
-- Uses combined division + seniority logic
-- Now checks ALL roles in the request - approver must be able to approve EVERY role
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Approver_CanApproveRequest]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Approver_CanApproveRequest]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Approver_CanApproveRequest]
    @ApproverUserId NVARCHAR(255),
    @RequestId BIGINT,
    @CanApprove BIT OUTPUT,
    @ApprovalReason NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RequesterUserId NVARCHAR(255);
    DECLARE @ApproverDivision NVARCHAR(255);
    DECLARE @ApproverSeniority INT;
    DECLARE @ApproverIsAdmin BIT;
    DECLARE @ApproverIsDataSteward BIT;
    DECLARE @ApproverIsApprover BIT;
    DECLARE @RequesterDivision NVARCHAR(255);
    DECLARE @RequesterSeniority INT;
    
    -- Get request details
    SELECT @RequesterUserId = UserId
    FROM [jit].[Requests]
    WHERE RequestId = @RequestId;
    
    IF @RequesterUserId IS NULL
    BEGIN
        SET @CanApprove = 0;
        SET @ApprovalReason = 'RequestNotFound';
        RETURN;
    END
    
    -- Get approver details
    SELECT 
        @ApproverDivision = Division,
        @ApproverSeniority = SeniorityLevel,
        @ApproverIsAdmin = IsAdmin,
        @ApproverIsDataSteward = IsDataSteward,
        @ApproverIsApprover = IsApprover
        FROM [jit].[vw_User_CurrentContext]
        WHERE UserId = @ApproverUserId
            AND IsEnabled = 1;
    
    -- Get requester details
    SELECT 
        @RequesterDivision = Division,
        @RequesterSeniority = SeniorityLevel
    FROM [jit].[vw_User_CurrentContext]
    WHERE UserId = @RequesterUserId;
    
    SET @CanApprove = 0;
    SET @ApprovalReason = 'NoPermission';
    
    -- Check 1: Admin override - admins can approve any request
    IF @ApproverIsAdmin = 1
    BEGIN
        SET @CanApprove = 1;
        SET @ApprovalReason = 'Admin';
        RETURN;
    END
    
    -- Get all roles in the request
    DECLARE @RoleCount INT = (SELECT COUNT(*) FROM [jit].[Request_Roles] WHERE RequestId = @RequestId);
    
    IF @RoleCount = 0
    BEGIN
        SET @CanApprove = 0;
        SET @ApprovalReason = 'NoRoles';
        RETURN;
    END
    
    -- Check 2: Data Steward - can approve any request from same division
    IF @ApproverIsDataSteward = 1
    BEGIN
        IF @ApproverDivision IS NOT NULL 
           AND @RequesterDivision IS NOT NULL 
           AND @ApproverDivision = @RequesterDivision
        BEGIN
            SET @CanApprove = 1;
            SET @ApprovalReason = 'DataSteward';
            RETURN;
        END
    END
    
    -- Check 3: IsApprover - approver must be able to request ALL roles AND have higher/equal seniority
    IF @ApproverIsApprover = 1
    BEGIN
        -- Check if approver can approve ALL roles
        -- For each role: approver must be able to request it AND have seniority >= requester
        DECLARE @CanApproveAllRoles BIT = 1;
        DECLARE @RoleId INT;
        DECLARE @CanRequestRole BIT;
        DECLARE @EligibilityReason NVARCHAR(255);
        
        -- Cursor to check each role
        DECLARE role_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT rr.RoleId
            FROM [jit].[Request_Roles] rr
            WHERE rr.RequestId = @RequestId;
        
        OPEN role_cursor;
        FETCH NEXT FROM role_cursor INTO @RoleId;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if approver can request this role
            EXEC [jit].[sp_User_Eligibility_Check]
                @UserId = @ApproverUserId,
                @RoleId = @RoleId,
                @CanRequest = @CanRequestRole OUTPUT,
                @EligibilityReason = @EligibilityReason OUTPUT;
            
            -- Approver can approve this role if:
            -- 1. They can request it themselves
            -- 2. Their seniority >= requester's seniority
            IF @CanRequestRole = 1
               AND (@ApproverSeniority IS NULL OR @RequesterSeniority IS NULL OR @ApproverSeniority >= @RequesterSeniority)
            BEGIN
                -- role is approvable, continue
                SET @CanApproveAllRoles = @CanApproveAllRoles;
            END
            ELSE
            BEGIN
                SET @CanApproveAllRoles = 0;
                BREAK;
            END
            
            FETCH NEXT FROM role_cursor INTO @RoleId;
        END
        
        CLOSE role_cursor;
        DEALLOCATE role_cursor;
        
        -- Approver can approve only if they can approve ALL roles
        IF @CanApproveAllRoles = 1
        BEGIN
            SET @CanApprove = 1;
            SET @ApprovalReason = 'ApproverEligibilityMatch';
            RETURN;
        END
    END
    
    -- If we get here, approver cannot approve all roles
    SET @CanApprove = 0;
    SET @ApprovalReason = 'CannotApproveAllRoles';
END
GO

