-- =============================================
-- Test Data: Insert Sample Users
-- =============================================
-- This script inserts sample users for testing
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT 'Inserting test users...'

-- Insert sample users with different seniority levels
INSERT INTO [jit].[Users] (
    LoginName, GivenName, Surname, DisplayName, Email, 
    Division, Department, JobTitle, SeniorityLevel, ManagerLoginName, 
    IsActive, LastAdSyncUtc, CreatedBy, UpdatedBy
)
VALUES
    -- Senior users (Level 4-5)
    ('DOMAIN\john.smith', 'John', 'Smith', 'John Smith', 'john.smith@company.com', 'Engineering', 'Data Engineering', 'Principal Data Engineer', 4, NULL, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('DOMAIN\sarah.jones', 'Sarah', 'Jones', 'Sarah Jones', 'sarah.jones@company.com', 'Engineering', 'Data Engineering', 'Director of Engineering', 5, NULL, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    
    -- Mid-level users (Level 2-3)
    ('DOMAIN\mike.wilson', 'Mike', 'Wilson', 'Mike Wilson', 'mike.wilson@company.com', 'Engineering', 'Data Engineering', 'Senior Data Engineer', 3, 'DOMAIN\john.smith', 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('DOMAIN\emily.brown', 'Emily', 'Brown', 'Emily Brown', 'emily.brown@company.com', 'Business', 'Analytics', 'Senior Business Analyst', 3, NULL, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('DOMAIN\david.lee', 'David', 'Lee', 'David Lee', 'david.lee@company.com', 'Engineering', 'DevOps', 'DevOps Engineer', 2, NULL, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    
    -- Junior users (Level 1)
    ('DOMAIN\alex.taylor', 'Alex', 'Taylor', 'Alex Taylor', 'alex.taylor@company.com', 'Engineering', 'Data Engineering', 'Junior Data Engineer', 1, 'DOMAIN\mike.wilson', 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('DOMAIN\jessica.martin', 'Jessica', 'Martin', 'Jessica Martin', 'jessica.martin@company.com', 'Business', 'Analytics', 'Business Analyst', 1, 'DOMAIN\emily.brown', 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    
    -- Approvers
    ('DOMAIN\admin.user', 'Admin', 'User', 'Admin User', 'admin.user@company.com', 'IT', 'Security', 'Security Administrator', 5, NULL, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('DOMAIN\approver1', 'Approver', 'One', 'Approver One', 'approver1@company.com', 'Engineering', 'Data Engineering', 'Data Manager', 4, NULL, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM');

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' users inserted'

GO

