-- =============================================
-- Backfill Script: UserContextVersionId references
-- Populates new context version FK columns and enforces integrity
-- Safe to run multiple times
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '========================================'
PRINT 'Backfilling UserContextVersionId columns'
PRINT '========================================'

DECLARE @Actor NVARCHAR(255) = SUSER_SNAME();
DECLARE @Now DATETIME2 = GETUTCDATE();

-- Ensure every user has an active context row.
INSERT INTO [jit].[User_Context_Versions] (
    UserId,
    Division,
    Department,
    JobTitle,
    IsAdmin,
    IsApprover,
    IsDataSteward,
    IsEnabled,
    IsActive,
    LastAdSyncUtc,
    ValidFromUtc,
    CreatedBy,
    UpdatedBy
)
SELECT
    u.UserId,
    u.Division,
    u.Department,
    u.JobTitle,
    u.IsAdmin,
    u.IsApprover,
    u.IsDataSteward,
    u.IsActive,
    1,
    u.LastAdSyncUtc,
    ISNULL(u.CreatedUtc, @Now),
    @Actor,
    @Actor
FROM [jit].[Users] u
WHERE NOT EXISTS (
    SELECT 1
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = u.UserId
      AND c.IsActive = 1
);

PRINT 'Inserted missing active user context rows: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));

-- Requests
UPDATE r
SET UserContextVersionId = pick.UserContextVersionId
FROM [jit].[Requests] r
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = r.UserId
      AND c.ValidFromUtc <= ISNULL(r.CreatedUtc, @Now)
      AND (c.ValidToUtc IS NULL OR c.ValidToUtc >= ISNULL(r.CreatedUtc, @Now))
    ORDER BY c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE r.UserContextVersionId IS NULL;

UPDATE r
SET UserContextVersionId = pick.UserContextVersionId
FROM [jit].[Requests] r
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = r.UserId
    ORDER BY c.IsActive DESC, c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE r.UserContextVersionId IS NULL;

PRINT 'Backfilled request context IDs';

-- Approvals
UPDATE a
SET ApproverUserContextVersionId = pick.UserContextVersionId
FROM [jit].[Approvals] a
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = a.ApproverUserId
      AND c.ValidFromUtc <= ISNULL(a.DecisionUtc, @Now)
      AND (c.ValidToUtc IS NULL OR c.ValidToUtc >= ISNULL(a.DecisionUtc, @Now))
    ORDER BY c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE a.ApproverUserId IS NOT NULL
  AND a.ApproverUserContextVersionId IS NULL;

UPDATE a
SET ApproverUserContextVersionId = pick.UserContextVersionId
FROM [jit].[Approvals] a
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = a.ApproverUserId
    ORDER BY c.IsActive DESC, c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE a.ApproverUserId IS NOT NULL
  AND a.ApproverUserContextVersionId IS NULL;

PRINT 'Backfilled approval context IDs';

-- Grants
UPDATE g
SET UserContextVersionId = pick.UserContextVersionId
FROM [jit].[Grants] g
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = g.UserId
      AND c.ValidFromUtc <= ISNULL(g.ValidFromUtc, @Now)
      AND (c.ValidToUtc IS NULL OR c.ValidToUtc >= ISNULL(g.ValidFromUtc, @Now))
    ORDER BY c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE g.UserContextVersionId IS NULL;

UPDATE g
SET UserContextVersionId = pick.UserContextVersionId
FROM [jit].[Grants] g
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = g.UserId
    ORDER BY c.IsActive DESC, c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE g.UserContextVersionId IS NULL;

UPDATE g
SET IssuedByUserContextVersionId = pick.UserContextVersionId
FROM [jit].[Grants] g
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = g.IssuedByUserId
      AND c.ValidFromUtc <= ISNULL(g.ValidFromUtc, @Now)
      AND (c.ValidToUtc IS NULL OR c.ValidToUtc >= ISNULL(g.ValidFromUtc, @Now))
    ORDER BY c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE g.IssuedByUserId IS NOT NULL
  AND g.IssuedByUserContextVersionId IS NULL;

UPDATE g
SET IssuedByUserContextVersionId = pick.UserContextVersionId
FROM [jit].[Grants] g
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = g.IssuedByUserId
    ORDER BY c.IsActive DESC, c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE g.IssuedByUserId IS NOT NULL
  AND g.IssuedByUserContextVersionId IS NULL;

PRINT 'Backfilled grant context IDs';

-- Audit log
UPDATE a
SET ActorUserContextVersionId = pick.UserContextVersionId
FROM [jit].[AuditLog] a
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = a.ActorUserId
      AND c.ValidFromUtc <= ISNULL(a.EventUtc, @Now)
      AND (c.ValidToUtc IS NULL OR c.ValidToUtc >= ISNULL(a.EventUtc, @Now))
    ORDER BY c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE a.ActorUserId IS NOT NULL
  AND a.ActorUserContextVersionId IS NULL;

UPDATE a
SET ActorUserContextVersionId = pick.UserContextVersionId
FROM [jit].[AuditLog] a
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = a.ActorUserId
    ORDER BY c.IsActive DESC, c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE a.ActorUserId IS NOT NULL
  AND a.ActorUserContextVersionId IS NULL;

UPDATE a
SET TargetUserContextVersionId = pick.UserContextVersionId
FROM [jit].[AuditLog] a
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = a.TargetUserId
      AND c.ValidFromUtc <= ISNULL(a.EventUtc, @Now)
      AND (c.ValidToUtc IS NULL OR c.ValidToUtc >= ISNULL(a.EventUtc, @Now))
    ORDER BY c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE a.TargetUserId IS NOT NULL
  AND a.TargetUserContextVersionId IS NULL;

UPDATE a
SET TargetUserContextVersionId = pick.UserContextVersionId
FROM [jit].[AuditLog] a
OUTER APPLY (
    SELECT TOP 1 c.UserContextVersionId
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = a.TargetUserId
    ORDER BY c.IsActive DESC, c.ValidFromUtc DESC, c.UserContextVersionId DESC
) pick
WHERE a.TargetUserId IS NOT NULL
  AND a.TargetUserContextVersionId IS NULL;

PRINT 'Backfilled audit context IDs';

-- Enforce strictness where business key is always present.
IF EXISTS (
    SELECT 1 FROM [jit].[Requests] WHERE UserContextVersionId IS NULL
)
BEGIN
    THROW 50110, 'Backfill failed: Requests has NULL UserContextVersionId rows', 1;
END

IF EXISTS (
    SELECT 1 FROM [jit].[Grants] WHERE UserContextVersionId IS NULL
)
BEGIN
    THROW 50111, 'Backfill failed: Grants has NULL UserContextVersionId rows', 1;
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[jit].[Requests]') AND name = 'UserContextVersionId' AND is_nullable = 1)
BEGIN
    ALTER TABLE [jit].[Requests] ALTER COLUMN [UserContextVersionId] BIGINT NOT NULL;
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[jit].[Grants]') AND name = 'UserContextVersionId' AND is_nullable = 1)
BEGIN
    ALTER TABLE [jit].[Grants] ALTER COLUMN [UserContextVersionId] BIGINT NOT NULL;
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Approvals_Context_WhenApproverSet' AND parent_object_id = OBJECT_ID(N'[jit].[Approvals]'))
BEGIN
    ALTER TABLE [jit].[Approvals]
    ADD CONSTRAINT [CK_Approvals_Context_WhenApproverSet]
    CHECK ([ApproverUserId] IS NULL OR [ApproverUserContextVersionId] IS NOT NULL);
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Grants_IssuerContext_WhenIssuerSet' AND parent_object_id = OBJECT_ID(N'[jit].[Grants]'))
BEGIN
    ALTER TABLE [jit].[Grants]
    ADD CONSTRAINT [CK_Grants_IssuerContext_WhenIssuerSet]
    CHECK ([IssuedByUserId] IS NULL OR [IssuedByUserContextVersionId] IS NOT NULL);
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Audit_ActorContext_WhenActorSet' AND parent_object_id = OBJECT_ID(N'[jit].[AuditLog]'))
BEGIN
    ALTER TABLE [jit].[AuditLog]
    ADD CONSTRAINT [CK_Audit_ActorContext_WhenActorSet]
    CHECK ([ActorUserId] IS NULL OR [ActorUserContextVersionId] IS NOT NULL);
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Audit_TargetContext_WhenTargetSet' AND parent_object_id = OBJECT_ID(N'[jit].[AuditLog]'))
BEGIN
    ALTER TABLE [jit].[AuditLog]
    ADD CONSTRAINT [CK_Audit_TargetContext_WhenTargetSet]
    CHECK ([TargetUserId] IS NULL OR [TargetUserContextVersionId] IS NOT NULL);
END

PRINT 'UserContextVersionId backfill and constraints completed successfully.';
GO
