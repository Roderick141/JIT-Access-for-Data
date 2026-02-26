USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_AuditLog_ListPaginated]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_AuditLog_ListPaginated]
GO
CREATE PROCEDURE [jit].[sp_AuditLog_ListPaginated]
    @Search NVARCHAR(255) = '',
    @EventType NVARCHAR(100) = '',
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH LogBase AS (
        SELECT
            a.AuditId AS AuditLogId,
            a.EventUtc,
            a.EventType,
            a.ActorUserId AS UserId,
            a.ActorUserContextVersionId,
            a.ActorLoginName,
            a.TargetUserId,
            a.TargetUserContextVersionId,
            a.RequestId,
            a.GrantId,
            a.DetailsJson AS Details,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN TRY_CONVERT(INT, JSON_VALUE(a.DetailsJson, '$.RoleId')) END AS RoleIdFromDetails,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN JSON_VALUE(a.DetailsJson, '$.RoleName') END AS RoleNameFromDetails,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN JSON_VALUE(a.DetailsJson, '$.RoleNames') END AS RoleNamesFromDetails,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN JSON_VALUE(a.DetailsJson, '$.DecisionComment') END AS DecisionCommentFromDetails,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN JSON_VALUE(a.DetailsJson, '$.TicketRef') END AS TicketRefFromDetails,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN TRY_CONVERT(INT, JSON_VALUE(a.DetailsJson, '$.RequestedDurationMinutes')) END AS RequestedDurationFromDetails,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN JSON_VALUE(a.DetailsJson, '$.ValidToUtc') END AS ValidToUtcFromDetails,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN TRY_CONVERT(DATETIME2(7), JSON_VALUE(a.DetailsJson, '$.ValidToUtc')) END AS ValidToUtcDtFromDetails,
            CASE
                WHEN ISJSON(a.DetailsJson) = 1 THEN JSON_VALUE(a.DetailsJson, '$.DbRoleName')
                WHEN a.DetailsJson LIKE '%"DbRoleName":"%' THEN
                    SUBSTRING(
                        a.DetailsJson,
                        CHARINDEX('"DbRoleName":"', a.DetailsJson) + LEN('"DbRoleName":"'),
                        CHARINDEX(
                            '"',
                            a.DetailsJson,
                            CHARINDEX('"DbRoleName":"', a.DetailsJson) + LEN('"DbRoleName":"')
                        ) - (CHARINDEX('"DbRoleName":"', a.DetailsJson) + LEN('"DbRoleName":"'))
                    )
            END AS DbRoleNameFromDetails,
            CASE
                WHEN ISJSON(a.DetailsJson) = 1 THEN JSON_VALUE(a.DetailsJson, '$.DatabaseName')
                WHEN a.DetailsJson LIKE '%"DatabaseName":"%' THEN
                    SUBSTRING(
                        a.DetailsJson,
                        CHARINDEX('"DatabaseName":"', a.DetailsJson) + LEN('"DatabaseName":"'),
                        CHARINDEX(
                            '"',
                            a.DetailsJson,
                            CHARINDEX('"DatabaseName":"', a.DetailsJson) + LEN('"DatabaseName":"')
                        ) - (CHARINDEX('"DatabaseName":"', a.DetailsJson) + LEN('"DatabaseName":"'))
                    )
            END AS DatabaseNameFromDetails,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN JSON_VALUE(a.DetailsJson, '$.Error') END AS ErrorFromDetails,
            CASE WHEN ISJSON(a.DetailsJson) = 1 THEN TRY_CONVERT(INT, JSON_VALUE(a.DetailsJson, '$.ExpiredCount')) END AS ExpiredCountFromDetails
        FROM [jit].[AuditLog] a
        WHERE (@Search = '' OR a.EventType LIKE '%' + @Search + '%' OR a.DetailsJson LIKE '%' + @Search + '%')
          AND (@EventType = '' OR a.EventType = @EventType)
          AND (@StartDate IS NULL OR a.EventUtc >= @StartDate)
          AND (@EndDate IS NULL OR a.EventUtc <= @EndDate)
    ),
    Enriched AS (
        SELECT
            lb.*,
            COALESCE(au.DisplayName, lb.UserId, lb.ActorLoginName, 'System') AS ActorDisplayName,
            COALESCE(tu.DisplayName, lb.TargetUserId, 'N/A') AS TargetDisplayName,
            req.Status AS RequestStatus,
            req.RequestedDurationMinutes AS RequestDurationMinutes,
            roleFromGrant.RoleName AS RoleNameFromGrant,
            roleFromRequest.RoleNames AS RoleNamesFromRequest,
            CASE
                WHEN lb.ValidToUtcDtFromDetails IS NOT NULL THEN
                    FORMAT(
                        (lb.ValidToUtcDtFromDetails AT TIME ZONE 'UTC' AT TIME ZONE 'W. Europe Standard Time'),
                        'dd-MM-yyyy HH:mm',
                        'nl-NL'
                    )
            END AS ValidToNlFromDetails
        FROM LogBase lb
        LEFT JOIN [jit].[User_Context_Versions] auc ON auc.UserContextVersionId = lb.ActorUserContextVersionId
        LEFT JOIN [jit].[Users] au ON au.UserId = COALESCE(auc.UserId, lb.UserId)
        LEFT JOIN [jit].[User_Context_Versions] tuc ON tuc.UserContextVersionId = lb.TargetUserContextVersionId
        LEFT JOIN [jit].[Users] tu ON tu.UserId = COALESCE(tuc.UserId, lb.TargetUserId)
        LEFT JOIN [jit].[Requests] req ON req.RequestId = lb.RequestId
        OUTER APPLY (
            SELECT TOP 1 r.RoleName
            FROM [jit].[Grants] g
            INNER JOIN [jit].[Roles] r ON r.RoleId = g.RoleId AND r.IsActive = 1
            WHERE g.GrantId = lb.GrantId
            ORDER BY r.RoleVersionId DESC
        ) roleFromGrant
        OUTER APPLY (
            SELECT STRING_AGG(r.RoleName, ', ') AS RoleNames
            FROM [jit].[Request_Roles] rr
            INNER JOIN [jit].[Roles] r ON r.RoleId = rr.RoleId AND r.IsActive = 1
            WHERE rr.RequestId = lb.RequestId
        ) roleFromRequest
    )
    SELECT
        e.AuditLogId,
        e.EventUtc,
        e.EventType,
        e.UserId,
        e.ActorDisplayName,
        e.TargetDisplayName,
        e.RequestId,
        e.GrantId,
        e.Details,
        COALESCE(
            NULLIF(e.RoleNameFromDetails, ''),
            NULLIF(e.RoleNameFromGrant, '')
        ) AS RoleName,
        COALESCE(
            NULLIF(e.RoleNamesFromDetails, ''),
            NULLIF(e.RoleNamesFromRequest, '')
        ) AS RoleNames,
        CASE
            WHEN e.EventType = 'RequestCreated' THEN
                'Request created for roles: ' + COALESCE(NULLIF(e.RoleNamesFromDetails, ''), NULLIF(e.RoleNamesFromRequest, ''), 'Unknown')
                + CASE WHEN e.RequestedDurationFromDetails IS NOT NULL THEN ' (' + CAST(e.RequestedDurationFromDetails AS NVARCHAR(20)) + ' min)' ELSE '' END
                + CASE WHEN e.TicketRefFromDetails IS NOT NULL AND e.TicketRefFromDetails <> '' THEN ', ticket ' + e.TicketRefFromDetails ELSE '' END
            WHEN e.EventType = 'Approved' THEN
                'Request approved for roles: ' + COALESCE(NULLIF(e.RoleNamesFromDetails, ''), NULLIF(e.RoleNamesFromRequest, ''), 'Unknown')
                + CASE WHEN e.DecisionCommentFromDetails IS NOT NULL AND e.DecisionCommentFromDetails <> '' THEN '. Comment: ' + e.DecisionCommentFromDetails ELSE '' END
            WHEN e.EventType = 'Denied' THEN
                'Request denied for roles: ' + COALESCE(NULLIF(e.RoleNamesFromDetails, ''), NULLIF(e.RoleNamesFromRequest, ''), 'Unknown')
                + CASE WHEN e.DecisionCommentFromDetails IS NOT NULL AND e.DecisionCommentFromDetails <> '' THEN '. Reason: ' + e.DecisionCommentFromDetails ELSE '' END
            WHEN e.EventType = 'RequestCancelled' THEN
                'Request cancelled for roles: ' + COALESCE(NULLIF(e.RoleNamesFromDetails, ''), NULLIF(e.RoleNamesFromRequest, ''), 'Unknown')
            WHEN e.EventType = 'GrantIssued' THEN
                'Grant issued for role: ' + COALESCE(NULLIF(e.RoleNameFromDetails, ''), NULLIF(e.RoleNameFromGrant, ''), 'Unknown')
                + CASE WHEN e.ValidToNlFromDetails IS NOT NULL AND e.ValidToNlFromDetails <> '' THEN ', valid to ' + e.ValidToNlFromDetails ELSE '' END
            WHEN e.EventType = 'GrantExpired' THEN
                'Grant expired for role: ' + COALESCE(NULLIF(e.RoleNameFromGrant, ''), 'Unknown')
            WHEN e.EventType = 'RoleAddError' THEN
                'Failed to add DB role ' + COALESCE(NULLIF(e.DbRoleNameFromDetails, ''), 'Unknown')
                + CASE WHEN e.DatabaseNameFromDetails IS NOT NULL AND e.DatabaseNameFromDetails <> '' THEN ' in ' + e.DatabaseNameFromDetails ELSE '' END
                + CASE WHEN e.ErrorFromDetails IS NOT NULL AND e.ErrorFromDetails <> '' THEN '. Error: ' + e.ErrorFromDetails ELSE '' END
            WHEN e.EventType = 'RoleDropError' THEN
                'Failed to drop DB role ' + COALESCE(NULLIF(e.DbRoleNameFromDetails, ''), 'Unknown')
                + CASE WHEN e.DatabaseNameFromDetails IS NOT NULL AND e.DatabaseNameFromDetails <> '' THEN ' in ' + e.DatabaseNameFromDetails ELSE '' END
                + CASE WHEN e.ErrorFromDetails IS NOT NULL AND e.ErrorFromDetails <> '' THEN '. Error: ' + e.ErrorFromDetails ELSE '' END
            WHEN e.EventType = 'ExpiredJobRun' THEN
                'Grant expiry job executed. Expired count: ' + COALESCE(CAST(e.ExpiredCountFromDetails AS NVARCHAR(20)), '0')
            ELSE
                e.EventType
        END AS DisplayMessage
    FROM Enriched e
    ORDER BY e.EventUtc DESC
    OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

