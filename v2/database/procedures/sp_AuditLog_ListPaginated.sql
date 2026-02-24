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
    SELECT
        a.AuditId AS AuditLogId,
        a.EventUtc,
        a.EventType,
        a.ActorUserId AS UserId,
        a.DetailsJson AS Details
    FROM [jit].[AuditLog] a
    WHERE (@Search = '' OR a.EventType LIKE '%' + @Search + '%' OR a.DetailsJson LIKE '%' + @Search + '%')
      AND (@EventType = '' OR a.EventType = @EventType)
      AND (@StartDate IS NULL OR a.EventUtc >= @StartDate)
      AND (@EndDate IS NULL OR a.EventUtc <= @EndDate)
    ORDER BY a.EventUtc DESC
    OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

