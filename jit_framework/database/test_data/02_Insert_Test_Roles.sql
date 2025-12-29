-- =============================================
-- Test Data: Insert Sample Roles
-- =============================================
-- This script inserts sample business roles for testing
-- =============================================

USE [DMAP_JIT_Permissions]
GO

PRINT 'Inserting test roles...'

-- Insert sample business roles with different approval requirements
INSERT INTO [jit].[Roles] (
    RoleName, Description, MaxDurationMinutes, RequiresTicket, 
    TicketRegex, RequiresJustification, RequiresApproval, 
    AutoApproveMinSeniority, IsEnabled, CreatedBy, UpdatedBy
)
VALUES
    -- Pre-approved role (no approval needed)
    ('Read-Only Reports', 'Access to read-only reporting views', 10080, 0, NULL, 1, 0, NULL, 1, 'SYSTEM', 'SYSTEM'),
    
    -- Seniority-based auto-approval (senior users auto-approved, juniors need approval)
    ('Advanced Analytics', 'Access to advanced analytics and data exploration', 10080, 0, NULL, 1, 1, 3, 1, 'SYSTEM', 'SYSTEM'),
    ('Data Warehouse Reader', 'Read access to data warehouse tables', 4320, 0, NULL, 1, 1, 3, 1, 'SYSTEM', 'SYSTEM'),
    
    -- Full approval required
    ('Full Database Access', 'Full read/write access to database', 1440, 1, '^TICKET-[0-9]+$', 1, 1, NULL, 1, 'SYSTEM', 'SYSTEM'),
    ('Data Administrator', 'Administrative access to database objects', 720, 1, '^TICKET-[0-9]+$', 1, 1, NULL, 1, 'SYSTEM', 'SYSTEM'),
    
    -- Quick access role (short duration, pre-approved)
    ('Temporary Query Access', 'Short-term access for ad-hoc queries', 240, 0, NULL, 1, 0, NULL, 1, 'SYSTEM', 'SYSTEM');

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' roles inserted'

GO

