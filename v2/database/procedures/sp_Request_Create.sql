-- =============================================
-- Stored Procedure: jit.sp_Request_Create
-- Creates new access request with multiple roles
-- Resolves eligibility rules per role for duration, justification, and approval.
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
    @UserId NVARCHAR(255),
    @RoleIds NVARCHAR(MAX),
    @RequestedDurationMinutes INT,
    @Justification NVARCHAR(MAX),
    @TicketRef NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentUser NVARCHAR(255) = SUSER_SNAME();
    DECLARE @CurrentUtc DATETIME2 = GETUTCDATE();
    DECLARE @RequestId BIGINT;
    DECLARE @Status NVARCHAR(50);
    DECLARE @UserSeniorityLevel INT;
    DECLARE @UserDept NVARCHAR(255);
    DECLARE @UserTitle NVARCHAR(255);
    DECLARE @UserDivision NVARCHAR(255);
    DECLARE @CanRequest BIT;
    DECLARE @EligibilityReason NVARCHAR(255);
    DECLARE @EligibilitySnapshotJson NVARCHAR(MAX);
    
    CREATE TABLE #RoleIds (RoleId INT PRIMARY KEY);
    
    -- Resolved eligibility rule parameters per role
    CREATE TABLE #ResolvedRoles (
        RoleId INT PRIMARY KEY,
        RoleName NVARCHAR(255),
        MaxDurationMinutes INT,
        RequiresJustification BIT,
        RequiresApproval BIT,
        MinSeniorityLevel INT NULL
    );
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @RoleIds IS NULL OR LEN(LTRIM(RTRIM(@RoleIds))) = 0
        BEGIN
            THROW 50000, 'At least one role must be specified', 1;
        END

        IF EXISTS (
            SELECT 1
            FROM STRING_SPLIT(@RoleIds, ',')
            WHERE LTRIM(RTRIM(value)) <> ''
              AND TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NULL
        )
        BEGIN
            THROW 50007, 'Invalid role ID list. Only comma-separated integers are allowed', 1;
        END
        
        INSERT INTO #RoleIds (RoleId)
        SELECT TRY_CONVERT(INT, LTRIM(RTRIM(value)))
        FROM STRING_SPLIT(@RoleIds, ',')
        WHERE LTRIM(RTRIM(value)) != '';
        
        IF NOT EXISTS (SELECT 1 FROM #RoleIds)
        BEGIN
            THROW 50000, 'No valid role IDs provided', 1;
        END
        
        -- Get user details
        SELECT 
            @UserSeniorityLevel = SeniorityLevel,
            @UserDept = Department,
            @UserTitle = JobTitle,
            @UserDivision = Division
        FROM [jit].[Users]
        WHERE UserId = @UserId;
        
        -- Validate all roles exist and are enabled, and resolve their eligibility rule parameters
        INSERT INTO #ResolvedRoles (RoleId, RoleName, MaxDurationMinutes, RequiresJustification, RequiresApproval, MinSeniorityLevel)
        SELECT
            r.RoleId,
            r.RoleName,
            matchedRule.MaxDurationMinutes,
            matchedRule.RequiresJustification,
            matchedRule.RequiresApproval,
            matchedRule.MinSeniorityLevel
        FROM [jit].[Roles] r
        INNER JOIN #RoleIds rid ON r.RoleId = rid.RoleId
        CROSS APPLY (
            SELECT TOP 1
                rer.MaxDurationMinutes,
                rer.RequiresJustification,
                rer.RequiresApproval,
                rer.MinSeniorityLevel
            FROM [jit].[Role_Eligibility_Rules] rer
            LEFT JOIN [jit].[User_Teams] ut
                ON rer.ScopeType = 'Team'
                AND CAST(ut.TeamId AS NVARCHAR(255)) = rer.ScopeValue
                AND ut.UserId = @UserId
                AND ut.IsActive = 1
            WHERE rer.RoleId = r.RoleId
            AND rer.IsActive = 1
            AND rer.CanRequest = 1
            AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= @CurrentUtc)
            AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= @CurrentUtc)
            AND (
                (rer.ScopeType = 'User' AND rer.ScopeValue = CAST(@UserId AS NVARCHAR(255)))
                OR (rer.ScopeType = 'Team' AND ut.UserId IS NOT NULL)
                OR (rer.ScopeType = 'Department' AND rer.ScopeValue = @UserDept AND @UserDept IS NOT NULL)
                OR (rer.ScopeType = 'Division' AND rer.ScopeValue = @UserDivision AND @UserDivision IS NOT NULL)
                OR (rer.ScopeType = 'All' AND rer.ScopeValue IS NULL)
            )
            ORDER BY
                CASE rer.ScopeType
                    WHEN 'User' THEN 5
                    WHEN 'Team' THEN 4
                    WHEN 'Department' THEN 3
                    WHEN 'Division' THEN 2
                    WHEN 'All' THEN 1
                END DESC,
                rer.Priority DESC
        ) AS matchedRule
        WHERE r.IsEnabled = 1 AND r.IsActive = 1;
        
        -- Check if all roles resolved
        DECLARE @RequestedRoleCount INT = (SELECT COUNT(*) FROM #RoleIds);
        DECLARE @ValidRoleCount INT = (SELECT COUNT(*) FROM #ResolvedRoles);
        
        IF @RequestedRoleCount != @ValidRoleCount
        BEGIN
            DECLARE @InvalidRoles NVARCHAR(MAX) = (
                SELECT STRING_AGG(CAST(rid.RoleId AS NVARCHAR(10)), ', ')
                FROM #RoleIds rid
                LEFT JOIN #ResolvedRoles rr ON rid.RoleId = rr.RoleId
                WHERE rr.RoleId IS NULL
            );
            DECLARE @ErrorMessage50002 NVARCHAR(MAX) = 'One or more roles not found, disabled, or no matching eligibility rule: ' + @InvalidRoles;
            THROW 50002, @ErrorMessage50002, 1;
        END
        
        -- Validate eligibility for ALL roles via sp_User_Eligibility_Check
        DECLARE @IneligibleRoles NVARCHAR(MAX) = '';
        DECLARE @CurrentRoleId INT;
        DECLARE role_cursor CURSOR FOR SELECT RoleId FROM #ResolvedRoles;
        
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
                DECLARE @RoleName NVARCHAR(255) = (SELECT RoleName FROM #ResolvedRoles WHERE RoleId = @CurrentRoleId);
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
        
        -- Check for existing active grants
        IF EXISTS (
            SELECT 1 FROM [jit].[Grants] g
            INNER JOIN #RoleIds rid ON g.RoleId = rid.RoleId
            WHERE g.UserId = @UserId AND g.Status = 'Active' AND g.ValidToUtc > @CurrentUtc
        )
        BEGIN
            DECLARE @ConflictingGrants NVARCHAR(MAX) = (
                SELECT STRING_AGG(rr.RoleName, ', ')
                FROM [jit].[Grants] g
                INNER JOIN #ResolvedRoles rr ON g.RoleId = rr.RoleId
                WHERE g.UserId = @UserId AND g.Status = 'Active' AND g.ValidToUtc > @CurrentUtc
            );
            DECLARE @ErrorMessage50003 NVARCHAR(MAX) = 'User already has an active grant for: ' + @ConflictingGrants;
            THROW 50003, @ErrorMessage50003, 1;
        END
        
        -- Check for existing pending requests
        IF EXISTS (
            SELECT 1 FROM [jit].[Requests] req
            INNER JOIN [jit].[Request_Roles] reqr ON req.RequestId = reqr.RequestId
            INNER JOIN #RoleIds rid ON reqr.RoleId = rid.RoleId
            WHERE req.UserId = @UserId AND req.Status IN ('Pending', 'AutoApproved')
        )
        BEGIN
            DECLARE @ConflictingRequests NVARCHAR(MAX) = (
                SELECT STRING_AGG(rr.RoleName, ', ')
                FROM [jit].[Requests] req
                INNER JOIN [jit].[Request_Roles] reqr ON req.RequestId = reqr.RequestId
                INNER JOIN #ResolvedRoles rr ON reqr.RoleId = rr.RoleId
                WHERE req.UserId = @UserId
                AND req.Status IN ('Pending', 'AutoApproved')
                AND rr.RoleId IN (SELECT RoleId FROM #RoleIds)
            );
            DECLARE @ErrorMessage50004 NVARCHAR(MAX) = 'User already has a pending or auto-approved request for: ' + @ConflictingRequests;
            THROW 50004, @ErrorMessage50004, 1;
        END
        
        -- Validate duration against minimum MaxDurationMinutes across resolved rules
        DECLARE @MinMaxDuration INT = (SELECT MIN(MaxDurationMinutes) FROM #ResolvedRoles);
        
        IF @RequestedDurationMinutes > @MinMaxDuration
        BEGIN
            DECLARE @ErrorMessage50005 NVARCHAR(MAX) = 'Requested duration (' + CAST(@RequestedDurationMinutes AS NVARCHAR(10)) + ' minutes) exceeds maximum allowed duration (' + CAST(@MinMaxDuration AS NVARCHAR(10)) + ' minutes) for selected roles';
            THROW 50005, @ErrorMessage50005, 1;
        END
        
        -- Validate justification: when any resolved rule has RequiresJustification=1,
        -- either Justification or TicketRef must be provided
        IF EXISTS (SELECT 1 FROM #ResolvedRoles WHERE RequiresJustification = 1)
        BEGIN
            DECLARE @HasJustification BIT = CASE WHEN @Justification IS NOT NULL AND LTRIM(RTRIM(@Justification)) != '' THEN 1 ELSE 0 END;
            DECLARE @HasTicket BIT = CASE WHEN @TicketRef IS NOT NULL AND LTRIM(RTRIM(@TicketRef)) != '' THEN 1 ELSE 0 END;
            
            IF @HasJustification = 0 AND @HasTicket = 0
            BEGIN
                THROW 50006, 'A justification or ticket reference is required for one or more selected roles', 1;
            END
        END
        
        -- Determine auto-approval
        DECLARE @AutoApprove BIT = 0;
        DECLARE @AutoApproveReason NVARCHAR(100) = NULL;
        
        -- All resolved rules have RequiresApproval=0 → auto-approve
        IF NOT EXISTS (SELECT 1 FROM #ResolvedRoles WHERE RequiresApproval = 1)
        BEGIN
            SET @AutoApprove = 1;
            SET @AutoApproveReason = 'PreApprovedRole';
            SET @Status = 'AutoApproved';
        END
        -- Seniority bypass: user meets all rules' MinSeniorityLevel thresholds
        ELSE IF @UserSeniorityLevel IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM #ResolvedRoles 
            WHERE RequiresApproval = 1
            AND (MinSeniorityLevel IS NULL OR @UserSeniorityLevel < MinSeniorityLevel)
        )
        BEGIN
            SET @AutoApprove = 1;
            SET @AutoApproveReason = 'SeniorityBypass';
            SET @Status = 'AutoApproved';
        END
        ELSE
        BEGIN
            SET @Status = 'Pending';
        END
        
        -- Build eligibility snapshot
        SELECT @EligibilitySnapshotJson = (
            SELECT
                rid.RoleId,
                roleDef.RoleVersionId,
                roleDef.RoleName,
                (
                    SELECT rer.EligibilityRuleVersionId, rer.ScopeType, rer.ScopeValue, rer.CanRequest, rer.Priority
                    FROM [jit].[Role_Eligibility_Rules] rer
                    WHERE rer.RoleId = rid.RoleId AND rer.IsActive = 1
                    FOR JSON PATH
                ) AS ActiveRules
            FROM #RoleIds rid
            INNER JOIN [jit].[Roles] roleDef ON roleDef.RoleId = rid.RoleId AND roleDef.IsActive = 1
            FOR JSON PATH
        );

        -- Create request
        INSERT INTO [jit].[Requests] (
            UserId, RequestedDurationMinutes, Justification, TicketRef,
            Status, UserDeptSnapshot, UserTitleSnapshot, EligibilitySnapshotJson, CreatedBy
        )
        VALUES (
            @UserId, @RequestedDurationMinutes, @Justification, @TicketRef,
            @Status, @UserDept, @UserTitle, @EligibilitySnapshotJson, @CurrentUser
        );
        
        SET @RequestId = SCOPE_IDENTITY();
        
        -- Insert role associations
        INSERT INTO [jit].[Request_Roles] (RequestId, RoleId)
        SELECT @RequestId, RoleId FROM #RoleIds;
        
        -- Audit log
        DECLARE @DetailsJson NVARCHAR(MAX) = 
            '{"RoleIds":[' + 
            (SELECT STRING_AGG(CAST(RoleId AS NVARCHAR(10)), ',') FROM #RoleIds) + 
            '],"Status":"' + @Status + '"';
        IF @AutoApproveReason IS NOT NULL
            SET @DetailsJson = @DetailsJson + ',"AutoApproveReason":"' + @AutoApproveReason + '"';
        SET @DetailsJson = @DetailsJson + '}';
        
        INSERT INTO [jit].[AuditLog] (EventType, ActorUserId, ActorLoginName, TargetUserId, RequestId, DetailsJson)
        VALUES ('RequestCreated', @UserId, @CurrentUser, @UserId, @RequestId, @DetailsJson);
        
        -- If auto-approved, create grants immediately
        IF @AutoApprove = 1
        BEGIN
            DECLARE @GrantId BIGINT;
            DECLARE @GrantValidFromUtc DATETIME2 = @CurrentUtc;
            DECLARE @GrantValidToUtc DATETIME2 = DATEADD(MINUTE, @RequestedDurationMinutes, @CurrentUtc);
            
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
    
    DROP TABLE #RoleIds;
    DROP TABLE #ResolvedRoles;
END
GO
