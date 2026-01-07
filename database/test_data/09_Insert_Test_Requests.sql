-- =============================================
-- Test Data: Insert Sample Requests
-- =============================================
-- This script inserts sample requests for testing
-- Note: Role associations are inserted separately in 09a_Insert_Test_Request_Roles.sql
-- =============================================
-- Note: This will create requests with various statuses (single and multi-role)

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Inserting test requests...'

DECLARE @UserId1 INT, @UserId2 INT, @UserId3 INT;

-- Get user IDs
SELECT @UserId1 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\mike.wilson';
SELECT @UserId2 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\alex.taylor';
SELECT @UserId3 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\emily.brown';

-- Request 1: Pending request (single role - requires approval)
INSERT INTO [jit].[Requests] (
    UserId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId2, 1440, 'Need access for quarterly reporting project', NULL,
    'Pending', 'Data Engineering', 'Junior Data Engineer', 'SYSTEM'
);

-- Request 2: Auto-approved request (single role - pre-approved role)
INSERT INTO [jit].[Requests] (
    UserId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId1, 10080, 'Weekly reporting requirements', NULL,
    'AutoApproved', 'Data Engineering', 'Senior Data Engineer', 'SYSTEM'
);

-- Request 3: Approved request (single role - was pending, then approved)
INSERT INTO [jit].[Requests] (
    UserId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId3, 2880, 'Need to analyze sales data for Q4 review', NULL,
    'Approved', 'Analytics', 'Senior Business Analyst', 'SYSTEM'
);

-- Request 4: Denied request (single role)
INSERT INTO [jit].[Requests] (
    UserId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId2, 1440, 'Need temporary access', NULL,
    'Denied', 'Data Engineering', 'Junior Data Engineer', 'SYSTEM'
);

-- Request 5: Pending multi-role request (2 roles)
INSERT INTO [jit].[Requests] (
    UserId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId1, 4320, 'Need multiple roles for comprehensive data analysis project', 'TICKET-2024-001',
    'Pending', 'Data Engineering', 'Senior Data Engineer', 'SYSTEM'
);

-- Request 6: Pending multi-role request (3 roles)
INSERT INTO [jit].[Requests] (
    UserId, RequestedDurationMinutes, Justification, TicketRef,
    Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
)
VALUES (
    @UserId3, 1440, 'Multi-role access needed for cross-functional project', 'TICKET-2024-002',
    'Pending', 'Analytics', 'Senior Business Analyst', 'SYSTEM'
);

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' test requests inserted'

GO
