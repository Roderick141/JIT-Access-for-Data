-- =============================================
-- Stored Procedure: jit.sp_Grant_Issue
-- Creates grant record and adds user to DB roles
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Grant_Issue]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Grant_Issue]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Grant_Issue]
    @RequestId BIGINT = NULL,
    @UserId NVARCHAR(255),
    @RoleId INT,
    @ValidFromUtc DATETIME2,
    @ValidToUtc DATETIME2,
    @IssuedByUserId NVARCHAR(255),
    @GrantId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @LoginName NVARCHAR(255);
    DECLARE @DbRoleName NVARCHAR(255);
    DECLARE @DatabaseName NVARCHAR(255);
    DECLARE @RoleVersionId BIGINT;
    DECLARE @ConfigSnapshotJson NVARCHAR(MAX);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get user login name
        SELECT @LoginName = LoginName
        FROM [jit].[Users]
        WHERE UserId = @UserId;
        
        IF @LoginName IS NULL
        BEGIN
            THROW 50003, 'User not found', 1;
        END
        
        SELECT TOP 1 @RoleVersionId = RoleVersionId
        FROM [jit].[Roles]
        WHERE RoleId = @RoleId AND IsActive = 1
        ORDER BY RoleVersionId DESC;

        SELECT @ConfigSnapshotJson = (
            SELECT
                r.RoleId, r.RoleVersionId, r.RoleName, r.Description, r.SensitivityLevel,
                r.IconName, r.IconColor,
                (
                    SELECT dbr.DbRoleId, dbr.DbRoleName, dbr.DatabaseName
                    FROM [jit].[Role_To_DB_Roles] map
                    INNER JOIN [jit].[DB_Roles] dbr ON dbr.DbRoleId = map.DbRoleId
                    WHERE map.RoleId = r.RoleId AND map.IsActive = 1
                    FOR JSON PATH
                ) AS DbRoleMappings
            FROM [jit].[Roles] r
            WHERE r.RoleVersionId = @RoleVersionId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Create grant record
        INSERT INTO [jit].[Grants] (
            RequestId, UserId, RoleId, RoleVersionId, ConfigSnapshotJson, ValidFromUtc, ValidToUtc,
            IssuedByUserId, Status
        )
        VALUES (
            @RequestId, @UserId, @RoleId, @RoleVersionId, @ConfigSnapshotJson, @ValidFromUtc, @ValidToUtc,
            @IssuedByUserId, 'Active'
        );
        
        SET @GrantId = SCOPE_IDENTITY();
        
        -- Get all DB roles for this business role and add user to each
        DECLARE role_cursor CURSOR FOR
        SELECT dbr.DatabaseName, dbr.DbRoleName, dbr.DbRoleId
        FROM [jit].[DB_Roles] dbr
        INNER JOIN [jit].[Role_To_DB_Roles] rtdbr ON dbr.DbRoleId = rtdbr.DbRoleId
        WHERE rtdbr.RoleId = @RoleId
        AND dbr.IsJitManaged = 1;
        
        DECLARE @DbRoleId INT;
        DECLARE @AddError NVARCHAR(MAX);
        
        OPEN role_cursor;
        FETCH NEXT FROM role_cursor INTO @DatabaseName, @DbRoleName, @DbRoleId;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @AddError = NULL;
            
            BEGIN TRY
                -- Add user to DB role in the target database
                DECLARE @Sql NVARCHAR(MAX) = 
                    'USE ' + QUOTENAME(@DatabaseName) + '; ' +
                    'ALTER ROLE ' + QUOTENAME(@DbRoleName) + ' ADD MEMBER ' + QUOTENAME(@LoginName);
                EXEC sp_executesql @Sql;
                
                -- Record success
                INSERT INTO [jit].[Grant_DBRole_Assignments] (
                    GrantId, DbRoleId, AddAttemptUtc, AddSucceeded
                )
                VALUES (
                    @GrantId, @DbRoleId, GETUTCDATE(), 1
                );
                
            END TRY
            BEGIN CATCH
                SET @AddError = ERROR_MESSAGE();
                
                -- Record failure
                INSERT INTO [jit].[Grant_DBRole_Assignments] (
                    GrantId, DbRoleId, AddAttemptUtc, AddSucceeded, AddError
                )
                VALUES (
                    @GrantId, @DbRoleId, GETUTCDATE(), 0, @AddError
                );
                
                -- Log error but continue with other roles
                INSERT INTO [jit].[AuditLog] (EventType, ActorLoginName, TargetUserId, GrantId, DetailsJson)
                VALUES ('RoleAddError', @CurrentUser, @UserId, @GrantId,
                    '{"DatabaseName":"' + @DatabaseName + '","DbRoleName":"' + @DbRoleName + '","Error":"' + REPLACE(@AddError, '"', '""') + '"}');
            END CATCH
            
            FETCH NEXT FROM role_cursor INTO @DatabaseName, @DbRoleName, @DbRoleId;
        END
        
        CLOSE role_cursor;
        DEALLOCATE role_cursor;
        
        -- Log audit
        INSERT INTO [jit].[AuditLog] (EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, GrantId, DetailsJson)
        VALUES ('GrantIssued', @IssuedByUserId, @CurrentUser, @UserId, @RequestId, @GrantId,
            '{"RoleId":' + CAST(@RoleId AS NVARCHAR(10)) + 
            ',"ValidToUtc":"' + CAST(@ValidToUtc AS NVARCHAR(50)) + '"}');
        
        -- Update request status if not already auto-approved
        IF @RequestId IS NOT NULL
        BEGIN
            UPDATE [jit].[Requests]
            SET Status = 'Approved',
                UpdatedUtc = GETUTCDATE()
            WHERE RequestId = @RequestId AND Status = 'Pending';
        END
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

