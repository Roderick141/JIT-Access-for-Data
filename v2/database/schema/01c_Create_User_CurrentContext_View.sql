-- =============================================
-- Create jit.vw_User_CurrentContext View
-- Projects the latest active user context version
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[jit].[vw_User_CurrentContext]', N'V') IS NOT NULL
    DROP VIEW [jit].[vw_User_CurrentContext]
GO

CREATE VIEW [jit].[vw_User_CurrentContext]
AS
SELECT
    u.UserId,
    u.LoginName,
    u.GivenName,
    u.Surname,
    u.DisplayName,
    u.Email,
    uc.UserContextVersionId,
    uc.Division,
    uc.Department,
    uc.JobTitle,
    uc.IsAdmin,
    uc.IsApprover,
    uc.IsDataSteward,
    uc.IsEnabled,
    uc.IsActive,
    uc.LastAdSyncUtc,
    uc.ValidFromUtc,
    uc.ValidToUtc,
    u.CreatedUtc,
    u.UpdatedUtc,
    u.CreatedBy,
    u.UpdatedBy
FROM [jit].[Users] u
OUTER APPLY (
    SELECT TOP 1
        c.UserContextVersionId,
        c.Division,
        c.Department,
        c.JobTitle,
        c.IsAdmin,
        c.IsApprover,
        c.IsDataSteward,
        c.IsEnabled,
        c.IsActive,
        c.LastAdSyncUtc,
        c.ValidFromUtc,
        c.ValidToUtc
    FROM [jit].[User_Context_Versions] c
    WHERE c.UserId = u.UserId
      AND c.IsActive = 1
    ORDER BY c.ValidFromUtc DESC, c.UserContextVersionId DESC
) uc
GO
