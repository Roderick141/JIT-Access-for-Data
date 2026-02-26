-- =============================================
-- Test Data: Insert History for John Smith
-- =============================================
-- Creates requests in all status types so every
-- history card style can be previewed in the UI.
-- Run AFTER the base test data scripts (01-11).
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '=== Inserting John Smith history test data ==='

DECLARE @JohnId   NVARCHAR(255) = 'john.smith';
DECLARE @Approver NVARCHAR(255);
SELECT  @Approver = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\approver1';

-- -----------------------------------------------
-- 1. PENDING request  (single role)
-- -----------------------------------------------
INSERT INTO [jit].[Requests]
    (UserId, RequestedDurationMinutes, Justification, TicketRef, Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy, CreatedUtc, UpdatedUtc)
VALUES
    (@JohnId, 1440, 'Need read-only access to prepare the weekly KPI dashboard for the leadership team.', 'INC-4010',
     'Pending', 'Data Engineering', 'Principal Data Engineer', 'SYSTEM',
     DATEADD(HOUR, -3, GETUTCDATE()), DATEADD(HOUR, -3, GETUTCDATE()));

DECLARE @PendingReqId BIGINT = SCOPE_IDENTITY();

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @PendingReqId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Read-Only Reports' AND IsActive = 1;

PRINT 'Pending request inserted (RequestId=' + CAST(@PendingReqId AS VARCHAR) + ')';

-- -----------------------------------------------
-- 2. APPROVED request  (single role, with approver)
-- -----------------------------------------------
INSERT INTO [jit].[Requests]
    (UserId, RequestedDurationMinutes, Justification, TicketRef, Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy, CreatedUtc, UpdatedUtc)
VALUES
    (@JohnId, 2880, 'Quarterly sales analysis requires data warehouse read access to build the Q4 revenue report.', NULL,
     'Approved', 'Data Engineering', 'Principal Data Engineer', 'SYSTEM',
     DATEADD(DAY, -5, GETUTCDATE()), DATEADD(DAY, -5, DATEADD(HOUR, 2, GETUTCDATE())));

DECLARE @ApprovedReqId BIGINT = SCOPE_IDENTITY();

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @ApprovedReqId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Data Warehouse Reader' AND IsActive = 1;

INSERT INTO [jit].[Approvals]
    (RequestId, ApproverUserId, ApproverLoginName, Decision, DecisionComment, DecisionUtc)
VALUES
    (@ApprovedReqId, @Approver, 'DOMAIN\approver1', 'Approved',
     'Access granted for quarterly analysis.',
     DATEADD(DAY, -5, DATEADD(HOUR, 2, GETUTCDATE())));

-- Grant for this approved request
INSERT INTO [jit].[Grants]
    (RequestId, UserId, RoleId, ValidFromUtc, ValidToUtc, IssuedByUserId, Status)
SELECT @ApprovedReqId, @JohnId, RoleId,
       DATEADD(DAY, -5, DATEADD(HOUR, 2, GETUTCDATE())),
       DATEADD(MINUTE, 2880, DATEADD(DAY, -5, DATEADD(HOUR, 2, GETUTCDATE()))),
       @Approver, 'Active'
FROM [jit].[Request_Roles] WHERE RequestId = @ApprovedReqId;

PRINT 'Approved request inserted (RequestId=' + CAST(@ApprovedReqId AS VARCHAR) + ')';

-- -----------------------------------------------
-- 3. AUTO-APPROVED request  (single role)
-- -----------------------------------------------
INSERT INTO [jit].[Requests]
    (UserId, RequestedDurationMinutes, Justification, TicketRef, Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy, CreatedUtc, UpdatedUtc)
VALUES
    (@JohnId, 10080, 'Standard reporting access for sprint review metrics.', NULL,
     'AutoApproved', 'Data Engineering', 'Principal Data Engineer', 'SYSTEM',
     DATEADD(DAY, -8, GETUTCDATE()), DATEADD(DAY, -8, GETUTCDATE()));

DECLARE @AutoReqId BIGINT = SCOPE_IDENTITY();

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @AutoReqId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Temporary Query Access' AND IsActive = 1;

-- Auto-approved requests create grants immediately
INSERT INTO [jit].[Grants]
    (RequestId, UserId, RoleId, ValidFromUtc, ValidToUtc, IssuedByUserId, Status)
SELECT @AutoReqId, @JohnId, RoleId,
       DATEADD(DAY, -8, GETUTCDATE()),
       DATEADD(MINUTE, 10080, DATEADD(DAY, -8, GETUTCDATE())),
       @JohnId, 'Expired'
FROM [jit].[Request_Roles] WHERE RequestId = @AutoReqId;

PRINT 'AutoApproved request inserted (RequestId=' + CAST(@AutoReqId AS VARCHAR) + ')';

-- -----------------------------------------------
-- 4. DENIED request  (single role, with reason)
-- -----------------------------------------------
INSERT INTO [jit].[Requests]
    (UserId, RequestedDurationMinutes, Justification, TicketRef, Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy, CreatedUtc, UpdatedUtc)
VALUES
    (@JohnId, 1440, 'Requesting full database access for data migration testing.', 'CHG-9021',
     'Denied', 'Data Engineering', 'Principal Data Engineer', 'SYSTEM',
     DATEADD(DAY, -12, GETUTCDATE()), DATEADD(DAY, -12, DATEADD(HOUR, 4, GETUTCDATE())));

DECLARE @DeniedReqId BIGINT = SCOPE_IDENTITY();

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @DeniedReqId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Full Database Access' AND IsActive = 1;

INSERT INTO [jit].[Approvals]
    (RequestId, ApproverUserId, ApproverLoginName, Decision, DecisionComment, DecisionUtc)
VALUES
    (@DeniedReqId, @Approver, 'DOMAIN\approver1', 'Denied',
     'Full database access is not permitted for migration testing. Please use the read-only role and coordinate with the DBA team.',
     DATEADD(DAY, -12, DATEADD(HOUR, 4, GETUTCDATE())));

PRINT 'Denied request inserted (RequestId=' + CAST(@DeniedReqId AS VARCHAR) + ')';

-- -----------------------------------------------
-- 5. CANCELLED request  (single role)
-- -----------------------------------------------
INSERT INTO [jit].[Requests]
    (UserId, RequestedDurationMinutes, Justification, TicketRef, Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy, CreatedUtc, UpdatedUtc)
VALUES
    (@JohnId, 4320, 'Data export needed for vendor deliverable - no longer needed.', NULL,
     'Cancelled', 'Data Engineering', 'Principal Data Engineer', 'SYSTEM',
     DATEADD(DAY, -15, GETUTCDATE()), DATEADD(DAY, -14, GETUTCDATE()));

DECLARE @CancelledReqId BIGINT = SCOPE_IDENTITY();

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @CancelledReqId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Data Export Access' AND IsActive = 1;

PRINT 'Cancelled request inserted (RequestId=' + CAST(@CancelledReqId AS VARCHAR) + ')';

-- -----------------------------------------------
-- 6. APPROVED multi-role request  (2 roles)
-- -----------------------------------------------
INSERT INTO [jit].[Requests]
    (UserId, RequestedDurationMinutes, Justification, TicketRef, Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy, CreatedUtc, UpdatedUtc)
VALUES
    (@JohnId, 4320, 'Cross-functional data analysis project requires both analytics and warehouse access.', 'PROJ-2024-042',
     'Approved', 'Data Engineering', 'Principal Data Engineer', 'SYSTEM',
     DATEADD(DAY, -20, GETUTCDATE()), DATEADD(DAY, -19, GETUTCDATE()));

DECLARE @MultiReqId BIGINT = SCOPE_IDENTITY();

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @MultiReqId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Advanced Analytics' AND IsActive = 1;

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @MultiReqId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Data Warehouse Reader' AND IsActive = 1;

INSERT INTO [jit].[Approvals]
    (RequestId, ApproverUserId, ApproverLoginName, Decision, DecisionComment, DecisionUtc)
VALUES
    (@MultiReqId, @Approver, 'DOMAIN\approver1', 'Approved',
     'Multi-role access approved for cross-functional project.',
     DATEADD(DAY, -19, GETUTCDATE()));

PRINT 'Multi-role approved request inserted (RequestId=' + CAST(@MultiReqId AS VARCHAR) + ')';

-- -----------------------------------------------
-- 7. PENDING multi-role request  (3 roles)
-- -----------------------------------------------
INSERT INTO [jit].[Requests]
    (UserId, RequestedDurationMinutes, Justification, TicketRef, Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy, CreatedUtc, UpdatedUtc)
VALUES
    (@JohnId, 1440, 'End-of-year audit requires broad temporary access to finalize compliance checks.', 'AUDIT-2024-007',
     'Pending', 'Data Engineering', 'Principal Data Engineer', 'SYSTEM',
     DATEADD(HOUR, -6, GETUTCDATE()), DATEADD(HOUR, -6, GETUTCDATE()));

DECLARE @MultiPendingId BIGINT = SCOPE_IDENTITY();

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @MultiPendingId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Read-Only Reports' AND IsActive = 1;

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @MultiPendingId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Data Warehouse Reader' AND IsActive = 1;

INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
SELECT @MultiPendingId, RoleId FROM [jit].[Roles] WHERE RoleName = 'Data Export Access' AND IsActive = 1;

PRINT 'Multi-role pending request inserted (RequestId=' + CAST(@MultiPendingId AS VARCHAR) + ')';

PRINT '=== John Smith history test data complete ==='

GO
