-- =============================================
-- Enable Change Data Capture (CDC) on Tables
-- Enables CDC on all tables that need to be tracked
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Enable CDC on jit.Users
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('jit.Users'))
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'jit',
        @source_name = N'Users',
        @role_name = N'cdc_admin',
        @supports_net_changes = 1
    PRINT 'CDC enabled on jit.Users'
END
ELSE
    PRINT 'CDC already enabled on jit.Users'
GO

-- Enable CDC on jit.Roles
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('jit.Roles'))
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'jit',
        @source_name = N'Roles',
        @role_name = N'cdc_admin',
        @supports_net_changes = 1
    PRINT 'CDC enabled on jit.Roles'
END
ELSE
    PRINT 'CDC already enabled on jit.Roles'
GO

-- Enable CDC on jit.Requests
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('jit.Requests'))
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'jit',
        @source_name = N'Requests',
        @role_name = N'cdc_admin',
        @supports_net_changes = 1
    PRINT 'CDC enabled on jit.Requests'
END
ELSE
    PRINT 'CDC already enabled on jit.Requests'
GO

-- Enable CDC on jit.Grants
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('jit.Grants'))
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'jit',
        @source_name = N'Grants',
        @role_name = N'cdc_admin',
        @supports_net_changes = 1
    PRINT 'CDC enabled on jit.Grants'
END
ELSE
    PRINT 'CDC already enabled on jit.Grants'
GO

-- Enable CDC on jit.Approvals
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('jit.Approvals'))
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'jit',
        @source_name = N'Approvals',
        @role_name = N'cdc_admin',
        @supports_net_changes = 1
    PRINT 'CDC enabled on jit.Approvals'
END
ELSE
    PRINT 'CDC already enabled on jit.Approvals'
GO

-- Enable CDC on jit.Request_Roles
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('jit.Request_Roles'))
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'jit',
        @source_name = N'Request_Roles',
        @role_name = N'cdc_admin',
        @supports_net_changes = 1
    PRINT 'CDC enabled on jit.Request_Roles'
END
ELSE
    PRINT 'CDC already enabled on jit.Request_Roles'
GO

-- Verify all tables have CDC enabled
SELECT 
    ct.capture_instance,
    OBJECT_SCHEMA_NAME(ct.source_object_id) + '.' + OBJECT_NAME(ct.source_object_id) AS SourceTable,
    ct.start_lsn,
    ct.create_date
FROM cdc.change_tables ct
WHERE OBJECT_SCHEMA_NAME(ct.source_object_id) = 'jit'
ORDER BY ct.create_date
GO

PRINT 'CDC table enablement complete!'
GO
