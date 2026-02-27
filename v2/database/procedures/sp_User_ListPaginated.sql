USE [DMAP_JIT_Permissions]
GO
IF OBJECT_ID(N'[jit].[sp_User_ListPaginated]', N'P') IS NOT NULL DROP PROCEDURE [jit].[sp_User_ListPaginated]
GO
CREATE PROCEDURE [jit].[sp_User_ListPaginated]
    @Search NVARCHAR(255) = '',
    @Department NVARCHAR(255) = '',
    @Role NVARCHAR(50) = '',
    @Status NVARCHAR(50) = '',
    @PageNumber INT = 1,
    @PageSize INT = 25
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *, COUNT(*) OVER() AS TotalCount
    FROM [jit].[vw_User_CurrentContext] u
    WHERE (@Search = '' OR u.DisplayName LIKE '%' + @Search + '%' OR u.Email LIKE '%' + @Search + '%')
      AND (@Department = '' OR u.Department = @Department)
      AND (
            @Role = ''
            OR (@Role = 'admin' AND u.IsAdmin = 1)
            OR (@Role = 'approver' AND u.IsApprover = 1)
            OR (@Role = 'steward' AND u.IsDataSteward = 1)
      )
      AND (@Status = '' OR (@Status = 'active' AND u.IsEnabled = 1) OR (@Status = 'inactive' AND u.IsEnabled = 0))
    ORDER BY u.DisplayName
    OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY
    OPTION (RECOMPILE);
END
GO

