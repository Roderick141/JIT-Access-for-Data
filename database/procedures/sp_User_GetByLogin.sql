-- =============================================
-- Stored Procedure: jit.sp_User_GetByLogin
-- Fast lookup by login name
-- Used throughout system for user resolution
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_User_GetByLogin]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_User_GetByLogin]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_User_GetByLogin]
    @LoginName NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        UserId,
        LoginName,
        GivenName,
        Surname,
        DisplayName,
        Email,
        Division,
        Department,
        JobTitle,
        SeniorityLevel,
        ManagerLoginName,
        IsAdmin,
        IsActive,
        LastAdSyncUtc,
        CreatedUtc,
        UpdatedUtc
    FROM [jit].[Users]
    WHERE LoginName = @LoginName;
END
GO

