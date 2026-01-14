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

-- Insert sample users with different seniority levels
-- UserId is the samaccountname (extracted from LoginName)
INSERT INTO [jit].[Users] (
    UserId, LoginName, GivenName, Surname, DisplayName, Email, 
    Division, Department, JobTitle, SeniorityLevel, 
    IsAdmin, IsApprover, IsDataSteward, IsActive, LastAdSyncUtc, CreatedBy, UpdatedBy
)
VALUES
    -- Senior users (Level 4-5)
    ('john.smith', 'DOMAIN\john.smith', 'John', 'Smith', 'John Smith', 'john.smith@company.com', 'Engineering', 'Data Engineering', 'Principal Data Engineer', 4, 0, 1, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('sarah.jones', 'DOMAIN\sarah.jones', 'Sarah', 'Jones', 'Sarah Jones', 'sarah.jones@company.com', 'Engineering', 'Data Engineering', 'Director of Engineering', 5, 0, 1, 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    
    -- Mid-level users (Level 2-3)
    ('mike.wilson', 'DOMAIN\mike.wilson', 'Mike', 'Wilson', 'Mike Wilson', 'mike.wilson@company.com', 'Engineering', 'Data Engineering', 'Senior Data Engineer', 3, 0, 0, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('emily.brown', 'DOMAIN\emily.brown', 'Emily', 'Brown', 'Emily Brown', 'emily.brown@company.com', 'Business', 'Analytics', 'Senior Business Analyst', 3, 0, 1, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('david.lee', 'DOMAIN\david.lee', 'David', 'Lee', 'David Lee', 'david.lee@company.com', 'Engineering', 'DevOps', 'DevOps Engineer', 2, 0, 0, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    
    -- Junior users (Level 1)
    ('alex.taylor', 'DOMAIN\alex.taylor', 'Alex', 'Taylor', 'Alex Taylor', 'alex.taylor@company.com', 'Engineering', 'Data Engineering', 'Junior Data Engineer', 1, 0, 0, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('jessica.martin', 'DOMAIN\jessica.martin', 'Jessica', 'Martin', 'Jessica Martin', 'jessica.martin@company.com', 'Business', 'Analytics', 'Business Analyst', 1, 0, 0, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    
    -- Admin and Approvers
    ('admin.user', 'DOMAIN\admin.user', 'Admin', 'User', 'Admin User', 'admin.user@company.com', 'IT', 'Security', 'Security Administrator', 5, 1, 1, 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    ('approver1', 'DOMAIN\approver1', 'Approver', 'One', 'Approver One', 'approver1@company.com', 'Engineering', 'Data Engineering', 'Data Manager', 4, 0, 1, 0, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM');

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' users inserted'

GO

