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
-- Note: These lookups work because we know the single-role requests from the test data
-- Request 1: Auto-approved for mike.wilson (UserId1)
SELECT TOP 1 @RequestId1 = RequestId 
FROM [jit].[Requests] 
WHERE Status = 'AutoApproved' 
  AND UserId = @UserId1
  AND RequestedDurationMinutes = 10080
ORDER BY CreatedUtc DESC;

-- Request 2: Approved for emily.brown (UserId2 in grants script variable, but UserId3 in requests)
-- Note: emily.brown is @UserId2 in this script
SELECT TOP 1 @RequestId2 = RequestId 
FROM [jit].[Requests] 
WHERE Status = 'Approved' 
  AND UserId = @UserId2
  AND RequestedDurationMinutes = 2880
ORDER BY CreatedUtc DESC;

-- Grant 1: Active grant (from auto-approved request - single role)
-- Get the role from Request_Roles for this request
IF @RequestId1 IS NOT NULL
BEGIN
    DECLARE @Grant1RoleId INT;
    SELECT @Grant1RoleId = RoleId FROM [jit].[Request_Roles] WHERE RequestId = @RequestId1;
    
    IF @Grant1RoleId IS NOT NULL
    BEGIN
        INSERT INTO [jit].[Grants] (
            RequestId, UserId, RoleId, ValidFromUtc, ValidToUtc,
            IssuedByUserId, Status
        )
        VALUES (
            @RequestId1, @UserId1, @Grant1RoleId, GETUTCDATE(), DATEADD(DAY, 7, GETUTCDATE()),
            @UserId1, 'Active'
        );
    END
END

-- Grant 2: Active grant (from approved request - single role)
-- Get the role from Request_Roles for this request
IF @RequestId2 IS NOT NULL
BEGIN
    DECLARE @Grant2RoleId INT;
    SELECT @Grant2RoleId = RoleId FROM [jit].[Request_Roles] WHERE RequestId = @RequestId2;
    
    IF @Grant2RoleId IS NOT NULL
    BEGIN
        INSERT INTO [jit].[Grants] (
            RequestId, UserId, RoleId, ValidFromUtc, ValidToUtc,
            IssuedByUserId, Status
        )
        VALUES (
            @RequestId2, @UserId2, @Grant2RoleId, GETUTCDATE(), DATEADD(DAY, 2, GETUTCDATE()),
            @IssuedByUserId, 'Active'
        );
    END
END

-- Grant 3: Expired grant (for testing expiry functionality)
INSERT INTO [jit].[Grants] (
    RequestId, UserId, RoleId, ValidFromUtc, ValidToUtc,
    IssuedByUserId, Status
)
VALUES (
    NULL, @UserId3, @RoleId3, DATEADD(DAY, -10, GETUTCDATE()), DATEADD(DAY, -5, GETUTCDATE()),
    @IssuedByUserId, 'Expired'
);

-- Note: @@ROWCOUNT may not be accurate due to IF blocks, so we count manually
DECLARE @GrantCount INT = (
    SELECT COUNT(*) FROM [jit].[Grants] 
    WHERE RequestId IN (@RequestId1, @RequestId2) 
       OR (RequestId IS NULL AND UserId = @UserId3)
);

PRINT CAST(@GrantCount AS VARCHAR(10)) + ' test grants inserted (including pre-existing grants)'

GO

