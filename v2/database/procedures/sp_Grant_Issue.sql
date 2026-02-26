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
    @UserContextVersionId BIGINT = NULL,
    @RoleId INT,
    @ValidFromUtc DATETIME2,
    @ValidToUtc DATETIME2,
    @IssuedByUserId NVARCHAR(255),
    @IssuedByUserContextVersionId BIGINT = NULL,
    @GrantId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @CurrentUtc DATETIME2 = GETUTCDATE();
    DECLARE @LoginName NVARCHAR(255);
    DECLARE @DbRoleName NVARCHAR(255);
    DECLARE @DatabaseName NVARCHAR(255);
    DECLARE @RoleVersionId BIGINT;
    DECLARE @ConfigSnapshotJson NVARCHAR(MAX);
    DECLARE @RoleName NVARCHAR(255);
    
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

        IF @UserContextVersionId IS NULL
        BEGIN
            SELECT @UserContextVersionId = UserContextVersionId
            FROM [jit].[vw_User_CurrentContext]
            WHERE UserId = @UserId;
        END

        IF @UserContextVersionId IS NULL
        BEGIN
            THROW 50008, 'Target user has no active context version', 1;
        END

        IF @IssuedByUserContextVersionId IS NULL AND @IssuedByUserId IS NOT NULL
        BEGIN
            SELECT @IssuedByUserContextVersionId = UserContextVersionId
            FROM [jit].[vw_User_CurrentContext]
            WHERE UserId = @IssuedByUserId;
        END

        IF @IssuedByUserId IS NOT NULL AND @IssuedByUserContextVersionId IS NULL
        BEGIN
            THROW 50009, 'Issuer has no active context version', 1;
        END
        
        SELECT TOP 1 @RoleVersionId = RoleVersionId
        FROM [jit].[Roles]
        WHERE RoleId = @RoleId AND IsActive = 1
        ORDER BY RoleVersionId DESC;

        SELECT TOP 1 @RoleName = RoleName
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
            RequestId, UserId, UserContextVersionId, RoleId, RoleVersionId, ConfigSnapshotJson, ValidFromUtc, ValidToUtc,
            IssuedByUserId, IssuedByUserContextVersionId, Status
        )
        VALUES (
            @RequestId, @UserId, @UserContextVersionId, @RoleId, @RoleVersionId, @ConfigSnapshotJson, @ValidFromUtc, @ValidToUtc,
            @IssuedByUserId, @IssuedByUserContextVersionId, 'Active'
        );
        
        SET @GrantId = SCOPE_IDENTITY();
        
        -- Get all DB roles for this business role and add user to each
        DECLARE role_cursor CURSOR FOR
        SELECT DISTINCT dbr.DatabaseName, dbr.DbRoleName, dbr.DbRoleId
        FROM [jit].[DB_Roles] dbr
        INNER JOIN [jit].[Role_To_DB_Roles] rtdbr ON dbr.DbRoleId = rtdbr.DbRoleId
        WHERE rtdbr.RoleId = @RoleId
        AND rtdbr.IsActive = 1
        AND (rtdbr.ValidFromUtc IS NULL OR rtdbr.ValidFromUtc <= @CurrentUtc)
        AND (rtdbr.ValidToUtc IS NULL OR rtdbr.ValidToUtc >= @CurrentUtc)
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
                
                -- Record success (idempotent update/insert)
                UPDATE [jit].[Grant_DBRole_Assignments]
                SET AddAttemptUtc = GETUTCDATE(),
                    AddSucceeded = 1,
                    AddError = NULL
                WHERE GrantId = @GrantId
                  AND DbRoleId = @DbRoleId;

                IF @@ROWCOUNT = 0
                BEGIN
                    INSERT INTO [jit].[Grant_DBRole_Assignments] (
                        GrantId, DbRoleId, AddAttemptUtc, AddSucceeded
                    )
                    VALUES (
                        @GrantId, @DbRoleId, GETUTCDATE(), 1
                    );
                END
                
            END TRY
            BEGIN CATCH
                SET @AddError = ERROR_MESSAGE();
                
                -- Record failure (idempotent update/insert)
                UPDATE [jit].[Grant_DBRole_Assignments]
                SET AddAttemptUtc = GETUTCDATE(),
                    AddSucceeded = 0,
                    AddError = @AddError
                WHERE GrantId = @GrantId
                  AND DbRoleId = @DbRoleId;

                IF @@ROWCOUNT = 0
                BEGIN
                    INSERT INTO [jit].[Grant_DBRole_Assignments] (
                        GrantId, DbRoleId, AddAttemptUtc, AddSucceeded, AddError
                    )
                    VALUES (
                        @GrantId, @DbRoleId, GETUTCDATE(), 0, @AddError
                    );
                END
                
                -- Log error but continue with other roles
                DECLARE @EscDbName NVARCHAR(MAX) = REPLACE(ISNULL(@DatabaseName, ''), '\', '\\');
                SET @EscDbName = REPLACE(@EscDbName, '"', '""');
                DECLARE @EscDbRole NVARCHAR(MAX) = REPLACE(ISNULL(@DbRoleName, ''), '\', '\\');
                SET @EscDbRole = REPLACE(@EscDbRole, '"', '""');
                DECLARE @EscAddError NVARCHAR(MAX) = REPLACE(ISNULL(@AddError, ''), '\', '\\');
                SET @EscAddError = REPLACE(@EscAddError, '"', '""');
                INSERT INTO [jit].[AuditLog] (
                    EventType,
                    ActorUserId,
                    ActorUserContextVersionId,
                    ActorLoginName,
                    TargetUserId,
                    TargetUserContextVersionId,
                    GrantId,
                    DetailsJson
                )
                VALUES ('RoleAddError', @IssuedByUserId, @IssuedByUserContextVersionId, @CurrentUser, @UserId, @UserContextVersionId, @GrantId,
                    '{"DatabaseName":"' + @EscDbName + '","DbRoleName":"' + @EscDbRole + '","Error":"' + @EscAddError + '"}');
            END CATCH
            
            FETCH NEXT FROM role_cursor INTO @DatabaseName, @DbRoleName, @DbRoleId;
        END
        
        CLOSE role_cursor;
        DEALLOCATE role_cursor;
        
        -- Log audit
        INSERT INTO [jit].[AuditLog] (
            EventType,
            ActorUserId,
            ActorUserContextVersionId,
            ActorLoginName,
            TargetUserId,
            TargetUserContextVersionId,
            RequestId,
            GrantId,
            DetailsJson
        )
        VALUES ('GrantIssued', @IssuedByUserId, @IssuedByUserContextVersionId, @CurrentUser, @UserId, @UserContextVersionId, @RequestId, @GrantId,
            '{"RoleId":' + CAST(@RoleId AS NVARCHAR(10)) +
            ',"RoleName":"' + ISNULL(REPLACE(@RoleName, '"', '""'), '') + '"' +
            ',"ValidFromUtc":"' + CAST(@ValidFromUtc AS NVARCHAR(50)) + '"' +
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
