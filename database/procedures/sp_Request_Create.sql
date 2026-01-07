-- =============================================
-- Stored Procedure: jit.sp_Request_Create
-- Creates new access request with multiple roles
-- Implements auto-approval logic (pre-approved roles and seniority-based)
-- @RoleIds: Comma-separated list of role IDs (e.g., "1,2,3")
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Request_Create]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Request_Create]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Request_Create]
    @UserId INT,
    @RoleIds NVARCHAR(MAX),  -- Comma-separated role IDs: "1,2,3"
    @RequestedDurationMinutes INT,
    @Justification NVARCHAR(MAX),
    @TicketRef NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @RequestId BIGINT;
    DECLARE @Status NVARCHAR(50);
    DECLARE @UserSeniorityLevel INT;
    DECLARE @UserDept NVARCHAR(255);
    DECLARE @UserTitle NVARCHAR(255);
    DECLARE @CanRequest BIT;
    DECLARE @EligibilityReason NVARCHAR(255);
    
    -- Temporary table to store role IDs
    CREATE TABLE #RoleIds (RoleId INT PRIMARY KEY);
    
    -- Temporary table for role details
    CREATE TABLE #RoleDetails (
        RoleId INT PRIMARY KEY,
        RoleName NVARCHAR(255),
        MaxDurationMinutes INT,
        RequiresTicket BIT,
        TicketRegex NVARCHAR(255),
        RequiresApproval BIT,
        AutoApproveMinSeniority INT,
        RequiresJustification BIT
    );
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Parse comma-separated role IDs into temp table
        IF @RoleIds IS NULL OR LEN(LTRIM(RTRIM(@RoleIds))) = 0
        BEGIN
            THROW 50000, 'At least one role must be specified', 1;
        END
        
        INSERT INTO #RoleIds (RoleId)
        SELECT CAST(value AS INT)
        FROM STRING_SPLIT(@RoleIds, ',')
        WHERE LTRIM(RTRIM(value)) != '';
        
        -- Validate we got at least one role
        IF NOT EXISTS (SELECT 1 FROM #RoleIds)
        BEGIN
            THROW 50000, 'No valid role IDs provided', 1;
        END
        
        -- Get role details for all specified roles
        INSERT INTO #RoleDetails (RoleId, RoleName, MaxDurationMinutes, RequiresTicket, TicketRegex, RequiresApproval, AutoApproveMinSeniority, RequiresJustification)
        SELECT r.RoleId, r.RoleName, r.MaxDurationMinutes, r.RequiresTicket, r.TicketRegex, r.RequiresApproval, r.AutoApproveMinSeniority, r.RequiresJustification
        FROM [jit].[Roles] r
        INNER JOIN #RoleIds rid ON r.RoleId = rid.RoleId
        WHERE r.IsEnabled = 1;
        
        -- Check if all roles exist and are enabled
        DECLARE @RequestedRoleCount INT = (SELECT COUNT(*) FROM #RoleIds);
        DECLARE @ValidRoleCount INT = (SELECT COUNT(*) FROM #RoleDetails);
        
        IF @RequestedRoleCount != @ValidRoleCount
        BEGIN
            DECLARE @InvalidRoles NVARCHAR(MAX) = (
                SELECT STRING_AGG(CAST(rid.RoleId AS NVARCHAR(10)), ', ')
                FROM #RoleIds rid
                LEFT JOIN #RoleDetails rd ON rid.RoleId = rd.RoleId
                WHERE rd.RoleId IS NULL
            );
            DECLARE @ErrorMessage50002 NVARCHAR(MAX) = 'One or more roles not found or disabled: ' + @InvalidRoles;
            THROW 50002, @ErrorMessage50002, 1;
        END
        
        -- Validate eligibility for ALL roles
        DECLARE @IneligibleRoles NVARCHAR(MAX) = '';
        DECLARE role_cursor CURSOR FOR SELECT RoleId FROM #RoleDetails;
        DECLARE @CurrentRoleId INT;
        
        OPEN role_cursor;
        FETCH NEXT FROM role_cursor INTO @CurrentRoleId;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC [jit].[sp_User_Eligibility_Check] 
                @UserId = @UserId,
                @RoleId = @CurrentRoleId,
                @CanRequest = @CanRequest OUTPUT,
                @EligibilityReason = @EligibilityReason OUTPUT;
            
            IF @CanRequest = 0
            BEGIN
                DECLARE @RoleName NVARCHAR(255) = (SELECT RoleName FROM #RoleDetails WHERE RoleId = @CurrentRoleId);
                IF LEN(@IneligibleRoles) > 0
                    SET @IneligibleRoles = @IneligibleRoles + ', ' + @RoleName;
                ELSE
                    SET @IneligibleRoles = @RoleName;
            END
            
            FETCH NEXT FROM role_cursor INTO @CurrentRoleId;
        END
        
        CLOSE role_cursor;
        DEALLOCATE role_cursor;
        
        IF LEN(@IneligibleRoles) > 0
        BEGIN
            DECLARE @ErrorMessage50001 NVARCHAR(MAX) = 'User is not eligible for the following roles: ' + @IneligibleRoles;
            THROW 50001, @ErrorMessage50001, 1;
        END
        
        -- Check if user already has active grants for ANY selected role
        IF EXISTS (
            SELECT 1 FROM [jit].[Grants] g
            INNER JOIN #RoleIds rid ON g.RoleId = rid.RoleId
            WHERE g.UserId = @UserId
            AND g.Status = 'Active'
            AND g.ValidToUtc > GETUTCDATE()
        )
        BEGIN
            DECLARE @ConflictingGrants NVARCHAR(MAX) = (
                SELECT STRING_AGG(rd.RoleName, ', ')
                FROM [jit].[Grants] g
                INNER JOIN #RoleDetails rd ON g.RoleId = rd.RoleId
                WHERE g.UserId = @UserId
                AND g.Status = 'Active'
                AND g.ValidToUtc > GETUTCDATE()
            );
            DECLARE @ErrorMessage50003 NVARCHAR(MAX) = 'User already has an active grant for: ' + @ConflictingGrants;
            THROW 50003, @ErrorMessage50003, 1;
        END
        
        -- Check if user already has pending requests for ANY selected role
        IF EXISTS (
            SELECT 1 FROM [jit].[Requests] req
            INNER JOIN [jit].[Request_Roles] rr ON req.RequestId = rr.RequestId
            INNER JOIN #RoleIds rid ON rr.RoleId = rid.RoleId
            WHERE req.UserId = @UserId
            AND req.Status IN ('Pending', 'AutoApproved')
        )
        BEGIN
            DECLARE @ConflictingRequests NVARCHAR(MAX) = (
                SELECT STRING_AGG(rd.RoleName, ', ')
                FROM [jit].[Requests] req
                INNER JOIN [jit].[Request_Roles] rr ON req.RequestId = rr.RequestId
                INNER JOIN #RoleDetails rd ON rr.RoleId = rd.RoleId
                WHERE req.UserId = @UserId
                AND req.Status IN ('Pending', 'AutoApproved')
                AND rd.RoleId IN (SELECT RoleId FROM #RoleIds)
            );
            DECLARE @ErrorMessage50004 NVARCHAR(MAX) = 'User already has a pending or auto-approved request for: ' + @ConflictingRequests;
            THROW 50004, @ErrorMessage50004, 1;
        END
        
        -- Calculate minimum MaxDurationMinutes across all roles
        DECLARE @MinMaxDuration INT = (SELECT MIN(MaxDurationMinutes) FROM #RoleDetails);
        
        -- Validate requested duration doesn't exceed minimum
        IF @RequestedDurationMinutes > @MinMaxDuration
        BEGIN
            DECLARE @ErrorMessage50005 NVARCHAR(MAX) = 'Requested duration (' + CAST(@RequestedDurationMinutes AS NVARCHAR(10)) + ' minutes) exceeds maximum allowed duration (' + CAST(@MinMaxDuration AS NVARCHAR(10)) + ' minutes) for selected roles';
            THROW 50005, @ErrorMessage50005, 1;
        END
        
        -- Check if ANY role requires ticket
        DECLARE @AnyRequiresTicket BIT = (SELECT MAX(CAST(RequiresTicket AS INT)) FROM #RoleDetails);
        
        IF @AnyRequiresTicket = 1 AND (@TicketRef IS NULL OR LTRIM(RTRIM(@TicketRef)) = '')
        BEGIN
            THROW 50006, 'Ticket reference is required for one or more selected roles', 1;
        END
        
        -- Validate ticket regex if provided and required
        -- Note: SQL Server LIKE is not full regex, so this is basic pattern validation
        -- For full regex support, validation should be done in application layer
        IF @AnyRequiresTicket = 1 AND @TicketRef IS NOT NULL
        BEGIN
            DECLARE @MatchingRoles NVARCHAR(MAX) = NULL;
            DECLARE @TicketRegex NVARCHAR(255);
            DECLARE @RoleNameForRegex NVARCHAR(255);
            DECLARE regex_cursor CURSOR FOR 
                SELECT RoleId, TicketRegex, RoleName 
                FROM #RoleDetails 
                WHERE RequiresTicket = 1 AND TicketRegex IS NOT NULL AND LTRIM(RTRIM(TicketRegex)) != '';
            
            OPEN regex_cursor;
            FETCH NEXT FROM regex_cursor INTO @CurrentRoleId, @TicketRegex, @RoleNameForRegex;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- SQL Server LIKE is not full regex, so this is basic pattern matching
                -- Application layer should do full regex validation
                IF @TicketRef NOT LIKE @TicketRegex
                BEGIN
                    IF @MatchingRoles IS NULL
                        SET @MatchingRoles = @RoleNameForRegex + ' (format: ' + @TicketRegex + ')';
                    ELSE
                        SET @MatchingRoles = @MatchingRoles + ', ' + @RoleNameForRegex + ' (format: ' + @TicketRegex + ')';
                END
                
                FETCH NEXT FROM regex_cursor INTO @CurrentRoleId, @TicketRegex, @RoleNameForRegex;
            END
            
            CLOSE regex_cursor;
            DEALLOCATE regex_cursor;
            
            IF @MatchingRoles IS NOT NULL
            BEGIN
                DECLARE @ErrorMessage50007 NVARCHAR(MAX) = 'Ticket reference format invalid for: ' + @MatchingRoles;
                THROW 50007, @ErrorMessage50007, 1;
            END
        END
        
        -- Get user details for snapshot
        SELECT 
            @UserSeniorityLevel = SeniorityLevel,
            @UserDept = Department,
            @UserTitle = JobTitle
        FROM [jit].[Users]
        WHERE UserId = @UserId;
        
        -- Determine if auto-approval applies (ALL roles must be auto-approvable)
        DECLARE @AutoApprove BIT = 0;
        DECLARE @AutoApproveReason NVARCHAR(100) = NULL;
        
        -- Check if ALL roles are pre-approved
        IF NOT EXISTS (SELECT 1 FROM #RoleDetails WHERE RequiresApproval = 1)
        BEGIN
            SET @AutoApprove = 1;
            SET @AutoApproveReason = 'PreApprovedRole';
            SET @Status = 'AutoApproved';
        END
        -- Check if user's seniority meets ALL roles' minimum requirements
        ELSE IF @UserSeniorityLevel IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM #RoleDetails 
            WHERE AutoApproveMinSeniority IS NOT NULL 
            AND (@UserSeniorityLevel < AutoApproveMinSeniority OR AutoApproveMinSeniority IS NULL)
        )
        BEGIN
            -- All roles have AutoApproveMinSeniority and user meets all
            SET @AutoApprove = 1;
            SET @AutoApproveReason = 'SeniorityBypass';
            SET @Status = 'AutoApproved';
        END
        ELSE
        BEGIN
            SET @Status = 'Pending';
        END
        
        -- Create request (no RoleId column)
        INSERT INTO [jit].[Requests] (
            UserId, RequestedDurationMinutes, Justification, TicketRef,
            Status, UserDeptSnapshot, UserTitleSnapshot, CreatedBy
        )
        VALUES (
            @UserId, @RequestedDurationMinutes, @Justification, @TicketRef,
            @Status, @UserDept, @UserTitle, @CurrentUser
        );
        
        SET @RequestId = SCOPE_IDENTITY();
        
        -- Insert role associations
        INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
        SELECT @RequestId, RoleId FROM #RoleIds;
        
        -- Log audit with all role IDs
        DECLARE @DetailsJson NVARCHAR(MAX) = 
            '{"RoleIds":[' + 
            (SELECT STRING_AGG(CAST(RoleId AS NVARCHAR(10)), ',') FROM #RoleIds) + 
            '],"Status":"' + @Status + '"';
        IF @AutoApproveReason IS NOT NULL
            SET @DetailsJson = @DetailsJson + ',"AutoApproveReason":"' + @AutoApproveReason + '"';
        SET @DetailsJson = @DetailsJson + '}';
        
        INSERT INTO [jit].[AuditLog] (EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, DetailsJson)
        VALUES ('RequestCreated', @UserId, @CurrentUser, @UserId, @RequestId, @DetailsJson);
        
        -- If auto-approved, create grants immediately (one per role)
        IF @AutoApprove = 1
        BEGIN
            DECLARE @GrantId BIGINT;
            DECLARE @GrantValidFromUtc DATETIME2 = GETUTCDATE();
            DECLARE @GrantValidToUtc DATETIME2 = DATEADD(MINUTE, @RequestedDurationMinutes, GETUTCDATE());
            
            DECLARE grant_cursor CURSOR FOR SELECT RoleId FROM #RoleIds;
            OPEN grant_cursor;
            FETCH NEXT FROM grant_cursor INTO @CurrentRoleId;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC [jit].[sp_Grant_Issue]
                    @RequestId = @RequestId,
                    @UserId = @UserId,
                    @RoleId = @CurrentRoleId,
                    @ValidFromUtc = @GrantValidFromUtc,
                    @ValidToUtc = @GrantValidToUtc,
                    @IssuedByUserId = @UserId,
                    @GrantId = @GrantId OUTPUT;
                
                FETCH NEXT FROM grant_cursor INTO @CurrentRoleId;
            END
            
            CLOSE grant_cursor;
            DEALLOCATE grant_cursor;
        END
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    
    -- Cleanup
    DROP TABLE #RoleIds;
    DROP TABLE #RoleDetails;
END
GO

PRINT 'Stored Procedure [jit].[sp_Request_Create] created successfully'
GO
