-- =============================================
-- Test Data: Insert Sample Requests
-- =============================================
-- This script inserts sample requests for testing
-- =============================================
-- Note: This will create requests with various statuses

USE [DMAP_JIT_Permissions]
GO

PRINT 'Inserting test requests...'

DECLARE @UserId1 INT, @UserId2 INT, @UserId3 INT;
DECLARE @RoleId1 INT, @RoleId2 INT, @RoleId3 INT, @RoleId4 INT;

-- Get user IDs
SELECT @UserId1 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\mike.wilson';
SELECT @UserId2 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\alex.taylor';
SELECT @UserId3 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\emily.brown';

-- Get role IDs
SELECT @RoleId1 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Read-Only Reports';
SELECT @RoleId2 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Advanced Analytics';
SELECT @RoleId3 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Data Warehouse Reader';
SELECT @RoleId4 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Temporary Query Access';

-- Request 1: Pending request (requires approval)
INSERT INTO [jit].[Requests] (
    UserId, RoleId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId2, @RoleId2, 1440, 'Need access for quarterly reporting project', NULL,
    'Pending', 'Data Engineering', 'Junior Data Engineer', 'SYSTEM'
);

-- Request 2: Auto-approved request (pre-approved role)
INSERT INTO [jit].[Requests] (
    UserId, RoleId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId1, @RoleId1, 10080, 'Weekly reporting requirements', NULL,
    'AutoApproved', 'Data Engineering', 'Senior Data Engineer', 'SYSTEM'
);

-- Request 3: Approved request (was pending, then approved)
INSERT INTO [jit].[Requests] (
    UserId, RoleId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId3, @RoleId3, 2880, 'Need to analyze sales data for Q4 review', NULL,
    'Approved', 'Analytics', 'Senior Business Analyst', 'SYSTEM'
);

-- Request 4: Denied request
INSERT INTO [jit].[Requests] (
    UserId, RoleId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId2, @RoleId4, 1440, 'Need temporary access', NULL,
    'Denied', 'Data Engineering', 'Junior Data Engineer', 'SYSTEM'
);

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' test requests inserted'

GO

