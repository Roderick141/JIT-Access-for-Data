-- =============================================
-- Test Data: Insert Sample Users
-- =============================================
-- This script inserts sample users for testing
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Inserting test users...'

-- Insert sample users
-- UserId is the samaccountname (extracted from LoginName)
INSERT INTO [jit].[Users] (
    UserId, LoginName, GivenName, Surname, DisplayName, Email, 
    Division, Department, JobTitle,
    IsAdmin, IsApprover, IsDataSteward, IsActive, LastAdSyncUtc, CreatedBy, UpdatedBy
)
VALUES
    ('john.smith', 'DOMAIN\john.smith', 'John', 'Smith', 'John Smith', 'john.smith@company.com', 'Engineering', 'Data Engineering', 'Principal Data Engineer', 0, 1, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('sarah.jones', 'DOMAIN\sarah.jones', 'Sarah', 'Jones', 'Sarah Jones', 'sarah.jones@company.com', 'Engineering', 'Data Engineering', 'Director of Engineering', 0, 1, 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    
    ('mike.wilson', 'DOMAIN\mike.wilson', 'Mike', 'Wilson', 'Mike Wilson', 'mike.wilson@company.com', 'Engineering', 'Data Engineering', 'Senior Data Engineer', 0, 0, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('emily.brown', 'DOMAIN\emily.brown', 'Emily', 'Brown', 'Emily Brown', 'emily.brown@company.com', 'Business', 'Analytics', 'Senior Business Analyst', 0, 1, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('david.lee', 'DOMAIN\david.lee', 'David', 'Lee', 'David Lee', 'david.lee@company.com', 'Engineering', 'DevOps', 'DevOps Engineer', 0, 0, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    
    ('alex.taylor', 'DOMAIN\alex.taylor', 'Alex', 'Taylor', 'Alex Taylor', 'alex.taylor@company.com', 'Engineering', 'Data Engineering', 'Junior Data Engineer', 0, 0, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('jessica.martin', 'DOMAIN\jessica.martin', 'Jessica', 'Martin', 'Jessica Martin', 'jessica.martin@company.com', 'Business', 'Analytics', 'Business Analyst', 0, 0, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    
    -- Admin and Approvers
    ('admin.user', 'DOMAIN\admin.user', 'Admin', 'User', 'Admin User', 'admin.user@company.com', 'IT', 'Security', 'Security Administrator', 1, 1, 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('approver1', 'DOMAIN\approver1', 'Approver', 'One', 'Approver One', 'approver1@company.com', 'Engineering', 'Data Engineering', 'Data Manager', 0, 1, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM');

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' users inserted'

INSERT INTO [jit].[User_Context_Versions] (
    UserId,
    Division,
    Department,
    JobTitle,
    IsAdmin,
    IsApprover,
    IsDataSteward,
    IsEnabled,
    IsActive,
    LastAdSyncUtc,
    ValidFromUtc,
    CreatedBy,
    UpdatedBy
)
SELECT
    u.UserId,
    u.Division,
    u.Department,
    u.JobTitle,
    u.IsAdmin,
    u.IsApprover,
    u.IsDataSteward,
    u.IsActive,
    1,
    u.LastAdSyncUtc,
    GETUTCDATE(),
    'SYSTEM',
    'SYSTEM'
FROM [jit].[Users] u
WHERE NOT EXISTS (
    SELECT 1
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = u.UserId
      AND c.IsActive = 1
);

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' user context rows inserted'

GO

