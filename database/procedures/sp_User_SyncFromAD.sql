-- =============================================
-- Stored Procedure: jit.sp_User_SyncFromAD
-- PowerShell/AD sync integration point
-- Upsert users from AD data
-- Marks users as inactive if missing from AD
-- Optionally sync SeniorityLevel from AD attribute
-- =============================================
-- Note: This expects a staging table jit.AD_Staging with columns:
-- LoginName, GivenName, Surname, DisplayName, Email, Division, Department, JobTitle, SeniorityLevel, ManagerLoginName

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
    DECLARE @UpdatedCount INT = 0;
    DECLARE @InsertedCount INT = 0;
    DECLARE @InactivatedCount INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Update existing users from staging table
        UPDATE u
        SET 
            GivenName = s.GivenName,
            Surname = s.Surname,
            DisplayName = s.DisplayName,
            Email = s.Email,
            Division = s.Division,
            Department = s.Department,
            JobTitle = s.JobTitle,
            SeniorityLevel = s.SeniorityLevel,
            ManagerLoginName = s.ManagerLoginName,
            LastAdSyncUtc = @SyncDate,
            UpdatedUtc = GETUTCDATE(),
            UpdatedBy = @SyncUser,
            IsActive = 1  -- Reactivate if was inactive
        FROM [jit].[Users] u
        INNER JOIN [jit].[AD_Staging] s ON u.LoginName = s.LoginName;
        
        SET @UpdatedCount = @@ROWCOUNT;
        
        -- Insert new users from staging table
        INSERT INTO [jit].[Users] (
            LoginName, GivenName, Surname, DisplayName, Email,
            Division, Department, JobTitle, SeniorityLevel, ManagerLoginName,
            IsAdmin, LastAdSyncUtc, CreatedBy, UpdatedBy
        )
        SELECT 
            s.LoginName, s.GivenName, s.Surname, s.DisplayName, s.Email,
            s.Division, s.Department, s.JobTitle, s.SeniorityLevel, s.ManagerLoginName,
            0, @SyncDate, @SyncUser, @SyncUser
        FROM [jit].[AD_Staging] s
        WHERE NOT EXISTS (SELECT 1 FROM [jit].[Users] u WHERE u.LoginName = s.LoginName);
        
        SET @InsertedCount = @@ROWCOUNT;
        
        -- Mark users as inactive if they're not in the staging table
        UPDATE u
        SET 
            IsActive = 0,
            UpdatedUtc = GETUTCDATE(),
            UpdatedBy = @SyncUser
        FROM [jit].[Users] u
        WHERE u.IsActive = 1
        AND NOT EXISTS (SELECT 1 FROM [jit].[AD_Staging] s WHERE s.LoginName = u.LoginName);
        
        SET @InactivatedCount = @@ROWCOUNT;
        
        -- Log sync activity
        INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, DetailsJson)
        VALUES ('AdSync', @SyncUser, 
            '{"UpdatedCount":' + CAST(@UpdatedCount AS NVARCHAR(10)) + 
            ',"InsertedCount":' + CAST(@InsertedCount AS NVARCHAR(10)) + 
            ',"InactivatedCount":' + CAST(@InactivatedCount AS NVARCHAR(10)) + '}');
        
        COMMIT TRANSACTION;
        
        SELECT 
            @UpdatedCount AS UpdatedCount,
            @InsertedCount AS InsertedCount,
            @InactivatedCount AS InactivatedCount;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, DetailsJson)
        VALUES ('AdSyncError', @SyncUser, 
            '{"Error":"' + ERROR_MESSAGE() + '","LineNumber":' + CAST(ERROR_LINE() AS NVARCHAR(10)) + '}');
            
        THROW;
    END CATCH
END
GO

-- Note: You'll need to create the AD_Staging table separately, or modify this procedure to work with your AD sync method

