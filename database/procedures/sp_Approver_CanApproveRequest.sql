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
    @ApproverUserId INT,
    @RequestId BIGINT,
    @CanApprove BIT OUTPUT,
    @ApprovalReason NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RequesterUserId INT;
    DECLARE @ApproverDivision NVARCHAR(255);
    DECLARE @ApproverSeniority INT;
    DECLARE @ApproverIsAdmin BIT;
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
        @ApproverIsAdmin = IsAdmin
    FROM [jit].[Users]
    WHERE UserId = @ApproverUserId;
    
    -- Get requester details
    SELECT 
        @RequesterDivision = Division,
        @RequesterSeniority = SeniorityLevel
    FROM [jit].[Users]
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
    
    -- Check 2: Division + Seniority - approver must be able to approve ALL roles
    -- Get all roles in the request
    DECLARE @RoleCount INT = (SELECT COUNT(*) FROM [jit].[Request_Roles] WHERE RequestId = @RequestId);
    
    IF @RoleCount = 0
    BEGIN
        SET @CanApprove = 0;
        SET @ApprovalReason = 'NoRoles';
        RETURN;
    END
    
    -- Check if approver can approve ALL roles
    -- For each role, approver must meet the AutoApproveMinSeniority threshold
    -- AND be in the same division as requester
    DECLARE @ApprovableRoleCount INT = (
        SELECT COUNT(*)
        FROM [jit].[Request_Roles] rr
        INNER JOIN [jit].[Roles] r ON rr.RoleId = r.RoleId
        WHERE rr.RequestId = @RequestId
        AND (
            -- Approver must be in same division as requester
            @ApproverDivision IS NOT NULL 
            AND @RequesterDivision IS NOT NULL 
            AND @ApproverDivision = @RequesterDivision
            AND r.AutoApproveMinSeniority IS NOT NULL
            AND @ApproverSeniority IS NOT NULL
            AND @ApproverSeniority >= r.AutoApproveMinSeniority
            AND @RequesterSeniority IS NOT NULL
            AND @RequesterSeniority < @ApproverSeniority
        )
    );
    
    -- Approver can approve only if they can approve ALL roles
    IF @ApprovableRoleCount = @RoleCount
    BEGIN
        SET @CanApprove = 1;
        SET @ApprovalReason = 'DivisionSeniorityMatch';
        RETURN;
    END
    
    -- If we get here, approver cannot approve all roles
    SET @CanApprove = 0;
    SET @ApprovalReason = 'CannotApproveAllRoles';
END
GO

PRINT 'Stored Procedure [jit].[sp_Approver_CanApproveRequest] created successfully'
GO
