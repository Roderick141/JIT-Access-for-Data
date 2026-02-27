-- =============================================
-- Stored Procedure: jit.sp_Grant_Expire
-- Called by expiry job to process expired grants
-- Removes role memberships and updates grant status
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Grant_Expire]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Grant_Expire]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Grant_Expire]
    @ExpiredCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = 'System';
    DECLARE @CurrentUtc DATETIME2 = GETUTCDATE();
    
    DECLARE @GrantId BIGINT;
    DECLARE @UserId NVARCHAR(255);
    DECLARE @UserContextVersionId BIGINT;
    DECLARE @LoginName NVARCHAR(255);
    DECLARE @DbRoleName NVARCHAR(255);
    DECLARE @DatabaseName NVARCHAR(255);
    DECLARE @DbRoleId INT;
    DECLARE @DropError NVARCHAR(MAX);
    
    SET @ExpiredCount = 0;
    
    -- Find expired active grants
    DECLARE grant_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT g.GrantId, g.UserId, g.UserContextVersionId, u.LoginName
    FROM [jit].[Grants] g
    INNER JOIN [jit].[Users] u ON g.UserId = u.UserId
    WHERE g.Status = 'Active'
    AND g.ValidToUtc < @CurrentUtc;
    
    OPEN grant_cursor;
    FETCH NEXT FROM grant_cursor INTO @GrantId, @UserId, @UserContextVersionId, @LoginName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @UserContextVersionId IS NULL AND @UserId IS NOT NULL
        BEGIN
            SELECT @UserContextVersionId = UserContextVersionId
            FROM [jit].[vw_User_CurrentContext]
            WHERE UserId = @UserId;
        END

        BEGIN TRY
            BEGIN TRANSACTION;
            
            -- Get all DB roles for this grant and remove user from each
            DECLARE role_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT dbr.DatabaseName, dbr.DbRoleName, dbr.DbRoleId
            FROM [jit].[Grant_DBRole_Assignments] gdba
            INNER JOIN [jit].[DB_Roles] dbr ON gdba.DbRoleId = dbr.DbRoleId
            WHERE gdba.GrantId = @GrantId
            AND gdba.AddSucceeded = 1;
            
            OPEN role_cursor;
            FETCH NEXT FROM role_cursor INTO @DatabaseName, @DbRoleName, @DbRoleId;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @DropError = NULL;
                
                BEGIN TRY
                    -- Remove user from DB role in the target database
                    DECLARE @Sql NVARCHAR(MAX) = 
                        'USE ' + QUOTENAME(@DatabaseName) + '; ' +
                        'ALTER ROLE ' + QUOTENAME(@DbRoleName) + ' DROP MEMBER ' + QUOTENAME(@LoginName);
                    EXEC sp_executesql @Sql;
                    
                    -- Record success
                    UPDATE [jit].[Grant_DBRole_Assignments]
                    SET DropAttemptUtc = GETUTCDATE(),
                        DropSucceeded = 1
                    WHERE GrantId = @GrantId AND DbRoleId = @DbRoleId;
                    
                END TRY
                BEGIN CATCH
                    SET @DropError = ERROR_MESSAGE();
                    
                    -- Record failure
                    UPDATE [jit].[Grant_DBRole_Assignments]
                    SET DropAttemptUtc = GETUTCDATE(),
                        DropSucceeded = 0,
                        DropError = @DropError
                    WHERE GrantId = @GrantId AND DbRoleId = @DbRoleId;
                    
                    -- Log error
                    DECLARE @EscDropDbName NVARCHAR(MAX) = REPLACE(ISNULL(@DatabaseName, ''), '\', '\\');
                    SET @EscDropDbName = REPLACE(@EscDropDbName, '"', '""');
                    DECLARE @EscDropDbRole NVARCHAR(MAX) = REPLACE(ISNULL(@DbRoleName, ''), '\', '\\');
                    SET @EscDropDbRole = REPLACE(@EscDropDbRole, '"', '""');
                    DECLARE @EscDropError NVARCHAR(MAX) = REPLACE(ISNULL(@DropError, ''), '\', '\\');
                    SET @EscDropError = REPLACE(@EscDropError, '"', '""');
                    IF @UserId IS NOT NULL AND @UserContextVersionId IS NOT NULL
                    BEGIN
                        INSERT INTO [jit].[AuditLog] (
                            EventType,
                            ActorLoginName,
                            TargetUserId,
                            TargetUserContextVersionId,
                            GrantId,
                            DetailsJson
                        )
                        VALUES ('RoleDropError', @CurrentUser, @UserId, @UserContextVersionId, @GrantId,
                            '{"DatabaseName":"' + @EscDropDbName + '","DbRoleName":"' + @EscDropDbRole + '","Error":"' + @EscDropError + '"}');
                    END
                    ELSE
                    BEGIN
                        INSERT INTO [jit].[AuditLog] (
                            EventType,
                            ActorLoginName,
                            GrantId,
                            DetailsJson
                        )
                        VALUES (
                            'RoleDropError',
                            @CurrentUser,
                            @GrantId,
                            '{"DatabaseName":"' + @EscDropDbName + '","DbRoleName":"' + @EscDropDbRole + '","Error":"' + @EscDropError + '","MissingUserContext":true}'
                        );
                    END
                END CATCH
                
                FETCH NEXT FROM role_cursor INTO @DatabaseName, @DbRoleName, @DbRoleId;
            END
            
            CLOSE role_cursor;
            DEALLOCATE role_cursor;
            
            -- Update grant status
            UPDATE [jit].[Grants]
            SET Status = 'Expired'
            WHERE GrantId = @GrantId;
            
            -- Log audit
            IF @UserId IS NOT NULL AND @UserContextVersionId IS NOT NULL
            BEGIN
                INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, TargetUserId, TargetUserContextVersionId, GrantId, DetailsJson)
                VALUES ('GrantExpired', @CurrentUser, @UserId, @UserContextVersionId, @GrantId, '{}');
            END
            ELSE
            BEGIN
                INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, GrantId, DetailsJson)
                VALUES ('GrantExpired', @CurrentUser, @GrantId, '{"MissingUserContext":true}');
            END
            
            SET @ExpiredCount = @ExpiredCount + 1;
            
            COMMIT TRANSACTION;
            
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            -- Log error but continue with next grant
            DECLARE @EscGrantExpireError NVARCHAR(MAX) = REPLACE(ISNULL(ERROR_MESSAGE(), ''), '\', '\\');
            SET @EscGrantExpireError = REPLACE(@EscGrantExpireError, '"', '""');
            IF @UserId IS NOT NULL AND @UserContextVersionId IS NOT NULL
            BEGIN
                INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, TargetUserId, TargetUserContextVersionId, GrantId, DetailsJson)
                VALUES ('GrantExpireError', @CurrentUser, @UserId, @UserContextVersionId, @GrantId,
                    '{"Error":"' + @EscGrantExpireError + '"}');
            END
            ELSE
            BEGIN
                INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, GrantId, DetailsJson)
                VALUES (
                    'GrantExpireError',
                    @CurrentUser,
                    @GrantId,
                    '{"Error":"' + @EscGrantExpireError + '","MissingUserContext":true}'
                );
            END
        END CATCH
        
        FETCH NEXT FROM grant_cursor INTO @GrantId, @UserId, @UserContextVersionId, @LoginName;
    END
    
    CLOSE grant_cursor;
    DEALLOCATE grant_cursor;
    
    -- Log job run
    INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, DetailsJson)
    VALUES ('ExpiredJobRun', @CurrentUser,
        '{"ExpiredCount":' + CAST(@ExpiredCount AS NVARCHAR(10)) + '}');
END
GO

