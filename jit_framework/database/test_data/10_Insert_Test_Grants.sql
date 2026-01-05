-- =============================================
-- Test Data: Insert Sample Grants
-- =============================================
-- This script inserts sample grants (active and expired) for testing
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Inserting test grants...'

DECLARE @UserId1 INT, @UserId2 INT, @UserId3 INT;
DECLARE @RoleId1 INT, @RoleId2 INT, @RoleId3 INT;
DECLARE @RequestId1 BIGINT, @RequestId2 BIGINT;
DECLARE @IssuedByUserId INT;

-- Get user IDs
SELECT @UserId1 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\mike.wilson';
SELECT @UserId2 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\emily.brown';
SELECT @UserId3 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\john.smith';
SELECT @IssuedByUserId = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\admin.user';

-- Get role IDs
SELECT @RoleId1 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Read-Only Reports';
SELECT @RoleId2 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Data Warehouse Reader';
SELECT @RoleId3 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Advanced Analytics';

-- Get request IDs (from previously inserted requests)
SELECT @RequestId1 = RequestId FROM [jit].[Requests] WHERE Status = 'AutoApproved' AND UserId = @UserId1;
SELECT @RequestId2 = RequestId FROM [jit].[Requests] WHERE Status = 'Approved' AND UserId = @UserId2;

-- Grant 1: Active grant (from auto-approved request)
INSERT INTO [jit].[Grants] (
    RequestId, UserId, RoleId, ValidFromUtc, ValidToUtc,
    IssuedByUserId, Status
)
VALUES (
    @RequestId1, @UserId1, @RoleId1, GETUTCDATE(), DATEADD(DAY, 7, GETUTCDATE()),
    @UserId1, 'Active'
);

-- Grant 2: Active grant (from approved request)
INSERT INTO [jit].[Grants] (
    RequestId, UserId, RoleId, ValidFromUtc, ValidToUtc,
    IssuedByUserId, Status
)
VALUES (
    @RequestId2, @UserId2, @RoleId2, GETUTCDATE(), DATEADD(DAY, 2, GETUTCDATE()),
    @IssuedByUserId, 'Active'
);

-- Grant 3: Expired grant (for testing expiry functionality)
INSERT INTO [jit].[Grants] (
    RequestId, UserId, RoleId, ValidFromUtc, ValidToUtc,
    IssuedByUserId, Status
)
VALUES (
    NULL, @UserId3, @RoleId3, DATEADD(DAY, -10, GETUTCDATE()), DATEADD(DAY, -5, GETUTCDATE()),
    @IssuedByUserId, 'Expired'
);

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' test grants inserted'

GO

