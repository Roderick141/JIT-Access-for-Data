-- =============================================
-- Stored Procedure: jit.sp_User_SyncFromAD
-- PowerShell/AD sync integration point
-- Upsert users from AD data
-- Maintains SCD2 context versions in jit.User_Context_Versions
-- Uses IsEnabled from AD as account enabled state
-- =============================================
-- Note: This expects a staging table jit.AD_Staging with columns:
-- UserId (samaccountname), LoginName, GivenName, Surname, DisplayName, Email,
-- Division, Department, JobTitle, SeniorityLevel, IsEnabled

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_User_SyncFromAD]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_User_SyncFromAD]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_User_SyncFromAD]
    @SyncDate DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @SyncDate IS NULL
        SET @SyncDate = GETUTCDATE();
    
    DECLARE @SyncUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @UpdatedIdentityCount INT = 0;
    DECLARE @InsertedIdentityCount INT = 0;
    DECLARE @InsertedContextCount INT = 0;
    DECLARE @ClosedContextCount INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Update existing user identity/profile fields
        UPDATE u
        SET 
            GivenName = s.GivenName,
            Surname = s.Surname,
            DisplayName = s.DisplayName,
            Email = s.Email,
            LastAdSyncUtc = @SyncDate,
            UpdatedUtc = GETUTCDATE(),
            UpdatedBy = @SyncUser,
            IsActive = 1
        FROM [jit].[Users] u
        INNER JOIN [jit].[AD_Staging] s ON u.LoginName = s.LoginName;
        
        SET @UpdatedIdentityCount = @@ROWCOUNT;
        
        -- Insert new users from staging table
        INSERT INTO [jit].[Users] (
            UserId, LoginName, GivenName, Surname, DisplayName, Email,
            LastAdSyncUtc, CreatedBy, UpdatedBy
        )
        SELECT 
            s.UserId, s.LoginName, s.GivenName, s.Surname, s.DisplayName, s.Email,
            @SyncDate, @SyncUser, @SyncUser
        FROM [jit].[AD_Staging] s
        WHERE NOT EXISTS (SELECT 1 FROM [jit].[Users] u WHERE u.LoginName = s.LoginName);
        
        SET @InsertedIdentityCount = @@ROWCOUNT;

        -- Close changed active context rows (SCD2 close-and-insert)
        UPDATE c
        SET
            c.IsActive = 0,
            c.ValidToUtc = @SyncDate,
            c.UpdatedUtc = GETUTCDATE(),
            c.UpdatedBy = @SyncUser
        FROM [jit].[User_Context_Versions] c
        INNER JOIN [jit].[Users] u ON u.UserId = c.UserId
        INNER JOIN [jit].[AD_Staging] s ON s.LoginName = u.LoginName
        WHERE c.IsActive = 1
          AND (
                ISNULL(c.Division, '') <> ISNULL(s.Division, '')
             OR ISNULL(c.Department, '') <> ISNULL(s.Department, '')
             OR ISNULL(c.JobTitle, '') <> ISNULL(s.JobTitle, '')
             OR ISNULL(c.SeniorityLevel, -2147483648) <> ISNULL(s.SeniorityLevel, -2147483648)
             OR c.IsEnabled <> ISNULL(s.IsEnabled, 1)
          );

        SET @ClosedContextCount = @ClosedContextCount + @@ROWCOUNT;

        -- Close currently active context for users no longer present in AD staging
        UPDATE c
        SET
            c.IsActive = 0,
            c.ValidToUtc = @SyncDate,
            c.UpdatedUtc = GETUTCDATE(),
            c.UpdatedBy = @SyncUser
        FROM [jit].[User_Context_Versions] c
        INNER JOIN [jit].[Users] u ON u.UserId = c.UserId
        WHERE c.IsActive = 1
          AND NOT EXISTS (
              SELECT 1 FROM [jit].[AD_Staging] s WHERE s.LoginName = u.LoginName
          );

        SET @ClosedContextCount = @ClosedContextCount + @@ROWCOUNT;

        -- Insert new active context rows for staged users with no active context
        -- or where prior active row was closed due to changes.
        INSERT INTO [jit].[User_Context_Versions] (
            UserId, Division, Department, JobTitle, SeniorityLevel,
            IsAdmin, IsApprover, IsDataSteward, IsEnabled,
            IsActive, LastAdSyncUtc, ValidFromUtc, ValidToUtc,
            CreatedBy, UpdatedBy
        )
        SELECT
            u.UserId,
            s.Division,
            s.Department,
            s.JobTitle,
            s.SeniorityLevel,
            ISNULL(prev.IsAdmin, 0),
            ISNULL(prev.IsApprover, 0),
            ISNULL(prev.IsDataSteward, 0),
            ISNULL(s.IsEnabled, 1),
            1,
            @SyncDate,
            @SyncDate,
            NULL,
            @SyncUser,
            @SyncUser
        FROM [jit].[Users] u
        INNER JOIN [jit].[AD_Staging] s ON s.LoginName = u.LoginName
        OUTER APPLY (
            SELECT TOP 1 p.IsAdmin, p.IsApprover, p.IsDataSteward
            FROM [jit].[User_Context_Versions] p
            WHERE p.UserId = u.UserId
            ORDER BY p.ValidFromUtc DESC, p.UserContextVersionId DESC
        ) prev
        WHERE NOT EXISTS (
            SELECT 1
            FROM [jit].[User_Context_Versions] c
            WHERE c.UserId = u.UserId
              AND c.IsActive = 1
        );

        SET @InsertedContextCount = @InsertedContextCount + @@ROWCOUNT;

        -- Insert disabled context rows for users missing from AD staging
        -- while retaining last known org/role metadata.
        INSERT INTO [jit].[User_Context_Versions] (
            UserId, Division, Department, JobTitle, SeniorityLevel,
            IsAdmin, IsApprover, IsDataSteward, IsEnabled,
            IsActive, LastAdSyncUtc, ValidFromUtc, ValidToUtc,
            CreatedBy, UpdatedBy
        )
        SELECT
            u.UserId,
            prev.Division,
            prev.Department,
            prev.JobTitle,
            prev.SeniorityLevel,
            ISNULL(prev.IsAdmin, 0),
            ISNULL(prev.IsApprover, 0),
            ISNULL(prev.IsDataSteward, 0),
            0,
            1,
            @SyncDate,
            @SyncDate,
            NULL,
            @SyncUser,
            @SyncUser
        FROM [jit].[Users] u
        OUTER APPLY (
            SELECT TOP 1
                p.Division,
                p.Department,
                p.JobTitle,
                p.SeniorityLevel,
                p.IsAdmin,
                p.IsApprover,
                p.IsDataSteward
            FROM [jit].[User_Context_Versions] p
            WHERE p.UserId = u.UserId
            ORDER BY p.ValidFromUtc DESC, p.UserContextVersionId DESC
        ) prev
        WHERE NOT EXISTS (
            SELECT 1 FROM [jit].[AD_Staging] s WHERE s.LoginName = u.LoginName
        )
          AND NOT EXISTS (
            SELECT 1
            FROM [jit].[User_Context_Versions] c
            WHERE c.UserId = u.UserId
              AND c.IsActive = 1
          );

        SET @InsertedContextCount = @InsertedContextCount + @@ROWCOUNT;

        -- Keep legacy Users columns synchronized for compatibility during transition.
        UPDATE u
        SET
            u.Division = c.Division,
            u.Department = c.Department,
            u.JobTitle = c.JobTitle,
            u.SeniorityLevel = c.SeniorityLevel,
            u.IsAdmin = c.IsAdmin,
            u.IsApprover = c.IsApprover,
            u.IsDataSteward = c.IsDataSteward,
            u.IsActive = c.IsEnabled,
            u.LastAdSyncUtc = @SyncDate,
            u.UpdatedUtc = GETUTCDATE(),
            u.UpdatedBy = @SyncUser
        FROM [jit].[Users] u
        INNER JOIN [jit].[vw_User_CurrentContext] c ON c.UserId = u.UserId;
        
        -- Log sync activity
        INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, DetailsJson)
        VALUES ('AdSync', @SyncUser, 
            '{"UpdatedIdentityCount":' + CAST(@UpdatedIdentityCount AS NVARCHAR(10)) + 
            ',"InsertedIdentityCount":' + CAST(@InsertedIdentityCount AS NVARCHAR(10)) + 
            ',"ClosedContextCount":' + CAST(@ClosedContextCount AS NVARCHAR(10)) + 
            ',"InsertedContextCount":' + CAST(@InsertedContextCount AS NVARCHAR(10)) + '}');
        
        COMMIT TRANSACTION;
        
        SELECT 
            @UpdatedIdentityCount AS UpdatedIdentityCount,
            @InsertedIdentityCount AS InsertedIdentityCount,
            @ClosedContextCount AS ClosedContextCount,
            @InsertedContextCount AS InsertedContextCount;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @EscAdSyncError NVARCHAR(MAX) = REPLACE(ISNULL(ERROR_MESSAGE(), ''), '\\', '\\\\');
        SET @EscAdSyncError = REPLACE(@EscAdSyncError, '"', '""');
            
        INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, DetailsJson)
        VALUES ('AdSyncError', @SyncUser, 
            '{"Error":"' + @EscAdSyncError + '","LineNumber":' + CAST(ERROR_LINE() AS NVARCHAR(10)) + '}');
            
        THROW;
    END CATCH
END
GO

-- Note: You'll need to create the AD_Staging table separately, or modify this procedure to work with your AD sync method

