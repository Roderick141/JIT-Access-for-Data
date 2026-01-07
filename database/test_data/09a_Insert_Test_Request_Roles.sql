-- =============================================
-- Test Data: Insert Request-Role Associations
-- =============================================
-- This script associates roles with requests created in 09_Insert_Test_Requests.sql
-- Supports both single-role and multi-role requests
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Inserting request-role associations...'

DECLARE @UserId1 INT, @UserId2 INT, @UserId3 INT;
DECLARE @RoleId1 INT, @RoleId2 INT, @RoleId3 INT, @RoleId4 INT, @RoleId5 INT;
DECLARE @RequestId1 BIGINT, @RequestId2 BIGINT, @RequestId3 BIGINT, @RequestId4 BIGINT;
DECLARE @RequestId5 BIGINT, @RequestId6 BIGINT;

-- Get user IDs
SELECT @UserId1 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\mike.wilson';
SELECT @UserId2 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\alex.taylor';
SELECT @UserId3 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\emily.brown';

-- Get role IDs
SELECT @RoleId1 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Read-Only Reports';
SELECT @RoleId2 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Advanced Analytics';
SELECT @RoleId3 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Data Warehouse Reader';
SELECT @RoleId4 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Temporary Query Access';
SELECT @RoleId5 = RoleId FROM [jit].[Roles] WHERE RoleName = 'Data Export Access';

-- Get request IDs (matching the order from 09_Insert_Test_Requests.sql)
-- Request 1: Pending single role
SELECT TOP 1 @RequestId1 = RequestId 
FROM [jit].[Requests] 
WHERE UserId = @UserId2 
  AND Status = 'Pending' 
  AND RequestedDurationMinutes = 1440
  AND Justification = 'Need access for quarterly reporting project'
ORDER BY CreatedUtc DESC;

-- Request 2: Auto-approved single role
SELECT TOP 1 @RequestId2 = RequestId 
FROM [jit].[Requests] 
WHERE UserId = @UserId1 
  AND Status = 'AutoApproved' 
  AND RequestedDurationMinutes = 10080
ORDER BY CreatedUtc DESC;

-- Request 3: Approved single role
SELECT TOP 1 @RequestId3 = RequestId 
FROM [jit].[Requests] 
WHERE UserId = @UserId3 
  AND Status = 'Approved' 
  AND RequestedDurationMinutes = 2880
ORDER BY CreatedUtc DESC;

-- Request 4: Denied single role
SELECT TOP 1 @RequestId4 = RequestId 
FROM [jit].[Requests] 
WHERE UserId = @UserId2 
  AND Status = 'Denied' 
  AND RequestedDurationMinutes = 1440
  AND Justification = 'Need temporary access'
ORDER BY CreatedUtc DESC;

-- Request 5: Pending multi-role (2 roles)
SELECT TOP 1 @RequestId5 = RequestId 
FROM [jit].[Requests] 
WHERE UserId = @UserId1 
  AND Status = 'Pending' 
  AND RequestedDurationMinutes = 4320
  AND TicketRef = 'TICKET-2024-001'
ORDER BY CreatedUtc DESC;

-- Request 6: Pending multi-role (3 roles)
SELECT TOP 1 @RequestId6 = RequestId 
FROM [jit].[Requests] 
WHERE UserId = @UserId3 
  AND Status = 'Pending' 
  AND RequestedDurationMinutes = 1440
  AND TicketRef = 'TICKET-2024-002'
ORDER BY CreatedUtc DESC;

-- Request 1: Single role (Advanced Analytics)
IF @RequestId1 IS NOT NULL AND @RoleId2 IS NOT NULL
BEGIN
    INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
    VALUES (@RequestId1, @RoleId2);
END

-- Request 2: Single role (Read-Only Reports)
IF @RequestId2 IS NOT NULL AND @RoleId1 IS NOT NULL
BEGIN
    INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
    VALUES (@RequestId2, @RoleId1);
END

-- Request 3: Single role (Data Warehouse Reader)
IF @RequestId3 IS NOT NULL AND @RoleId3 IS NOT NULL
BEGIN
    INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
    VALUES (@RequestId3, @RoleId3);
END

-- Request 4: Single role (Temporary Query Access)
IF @RequestId4 IS NOT NULL AND @RoleId4 IS NOT NULL
BEGIN
    INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
    VALUES (@RequestId4, @RoleId4);
END

-- Request 5: Multi-role (2 roles: Advanced Analytics + Data Warehouse Reader)
IF @RequestId5 IS NOT NULL AND @RoleId2 IS NOT NULL AND @RoleId3 IS NOT NULL
BEGIN
    INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
    VALUES (@RequestId5, @RoleId2);
    
    INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
    VALUES (@RequestId5, @RoleId3);
END

-- Request 6: Multi-role (3 roles: Read-Only Reports + Advanced Analytics + Data Export Access)
IF @RequestId6 IS NOT NULL AND @RoleId1 IS NOT NULL AND @RoleId2 IS NOT NULL AND @RoleId5 IS NOT NULL
BEGIN
    INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
    VALUES (@RequestId6, @RoleId1);
    
    INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
    VALUES (@RequestId6, @RoleId2);
    
    INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
    VALUES (@RequestId6, @RoleId5);
END

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' request-role associations inserted'

GO

