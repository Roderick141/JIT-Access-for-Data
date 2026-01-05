-- =============================================
-- Test Data: Insert Sample DB Roles
-- =============================================
-- This script inserts sample database role metadata
-- =============================================
-- Note: These DB roles should exist in your actual database
-- If they don't exist, create them first or adjust the names

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Inserting test DB roles...'
PRINT 'WARNING: Ensure these database roles exist in your database, or create them first!'

-- Insert sample database roles
INSERT INTO [jit].[DB_Roles] (
    DbRoleName, RoleType, Description, IsJitManaged, HasUnmask, CreatedBy, UpdatedBy
)
VALUES
    ('db_datareader', 'data_reader', 'Standard read-only access to all tables', 1, 0, 'SYSTEM', 'SYSTEM'),
    ('db_datawriter', 'data_writer', 'Read and write access to all tables', 1, 0, 'SYSTEM', 'SYSTEM'),
    ('JIT_Reports_Reader', 'mask_reader', 'Read access to reporting views (masked data)', 1, 0, 'SYSTEM', 'SYSTEM'),
    ('JIT_Reports_Unmasked', 'ddm_unmask', 'Read access to reporting views (unmasked data)', 1, 1, 'SYSTEM', 'SYSTEM'),
    ('JIT_Analytics', 'data_reader', 'Access to analytics tables and views', 1, 0, 'SYSTEM', 'SYSTEM');

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' DB roles inserted'
PRINT ''
PRINT 'Remember to create these roles in your database if they do not exist:'
PRINT '  CREATE ROLE JIT_Reports_Reader;'
PRINT '  CREATE ROLE JIT_Reports_Unmasked;'
PRINT '  CREATE ROLE JIT_Analytics;'

GO

