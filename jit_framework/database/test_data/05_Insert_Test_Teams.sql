-- =============================================
-- Test Data: Insert Sample Teams
-- =============================================
-- This script inserts sample teams for testing
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT 'Inserting test teams...'

-- Insert sample teams
INSERT INTO [jit].[Teams] (
    TeamName, Description, Division, Department, IsActive, CreatedBy, UpdatedBy
)
VALUES
    ('Data Engineering Team', 'Core data engineering and pipeline team', 'Engineering', 'Data Engineering', 1, 'SYSTEM', 'SYSTEM'),
    ('Analytics Team', 'Business analytics and reporting team', 'Business', 'Analytics', 1, 'SYSTEM', 'SYSTEM'),
    ('DevOps Team', 'Infrastructure and DevOps team', 'Engineering', 'DevOps', 1, 'SYSTEM', 'SYSTEM'),
    ('Security Team', 'IT Security and compliance team', 'IT', 'Security', 1, 'SYSTEM', 'SYSTEM');

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' teams inserted'

GO

