-- =============================================
-- Test Data: Insert Sample Roles
-- =============================================
-- This script inserts sample business roles for testing
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Inserting test roles...'

-- Insert sample business roles with different approval requirements
INSERT INTO [jit].[Roles] (
    RoleId, RoleName, Description, SensitivityLevel, IconName, IconColor,
    IsEnabled, IsActive, ValidFromUtc, CreatedBy, UpdatedBy
)
VALUES
    (1, 'Read-Only Reports', 'Access to read-only reporting views', 'Standard', 'Database', 'bg-blue-500', 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    (2, 'Advanced Analytics', 'Access to advanced analytics and data exploration', 'Sensitive', 'BarChart3', 'bg-indigo-500', 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    (3, 'Data Warehouse Reader', 'Read access to data warehouse tables', 'Standard', 'Table', 'bg-teal-500', 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    (4, 'Full Database Access', 'Full read/write access to database', 'Sensitive', 'DatabaseZap', 'bg-red-500', 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    (5, 'Data Administrator', 'Administrative access to database objects', 'Sensitive', 'ShieldCheck', 'bg-orange-500', 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    (6, 'Temporary Query Access', 'Short-term access for ad-hoc queries', 'Standard', 'Clock', 'bg-gray-500', 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM'),
    (7, 'Data Export Access', 'Access to export data extracts for approved use-cases', 'Sensitive', 'Download', 'bg-purple-500', 1, 1, GETUTCDATE(), 'SYSTEM', 'SYSTEM');

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' roles inserted'

GO

