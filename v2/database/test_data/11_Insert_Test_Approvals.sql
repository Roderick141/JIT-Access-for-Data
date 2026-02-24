-- =============================================
-- Test Data: Insert Sample Approvals
-- =============================================
-- This script inserts sample approval records
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Inserting test approvals...'

DECLARE @RequestId1 BIGINT, @RequestId2 BIGINT;
DECLARE @ApproverUserId NVARCHAR(255);
DECLARE @UserId2 NVARCHAR(255), @UserId3 NVARCHAR(255);

-- Get user IDs (samaccountname)
SELECT @ApproverUserId = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\approver1';
SELECT @UserId2 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\alex.taylor';
SELECT @UserId3 = UserId FROM [jit].[Users] WHERE LoginName = 'DOMAIN\emily.brown';

-- Get request IDs
SELECT @RequestId1 = RequestId FROM [jit].[Requests] WHERE Status = 'Approved' AND UserId = @UserId3;
SELECT @RequestId2 = RequestId FROM [jit].[Requests] WHERE Status = 'Denied' AND UserId = @UserId2;

-- Approval 1: Approved request
IF @RequestId1 IS NOT NULL
BEGIN
    INSERT INTO [jit].[Approvals] (
        RequestId, ApproverUserId, ApproverLoginName, Decision, DecisionComment, DecisionUtc
    )
    VALUES (
        @RequestId1, @ApproverUserId, 'DOMAIN\approver1', 'Approved', 
        'Access granted for quarterly analysis', DATEADD(HOUR, -2, GETUTCDATE())
    );
END

-- Approval 2: Denied request
IF @RequestId2 IS NOT NULL
BEGIN
    INSERT INTO [jit].[Approvals] (
        RequestId, ApproverUserId, ApproverLoginName, Decision, DecisionComment, DecisionUtc
    )
    VALUES (
        @RequestId2, @ApproverUserId, 'DOMAIN\approver1', 'Denied', 
        'Insufficient justification provided', DATEADD(HOUR, -1, GETUTCDATE())
    );
END

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' approval records inserted'

GO

