-- =============================================
-- Stored Procedure: jit.sp_Role_ListRequestable
-- Returns roles user can request (based on eligibility rules + enabled)
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Role_ListRequestable]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Role_ListRequestable]
GO

CREATE PROCEDURE [jit].[sp_Role_ListRequestable]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check each enabled role for eligibility
    SELECT 
        r.RoleId,
        r.RoleName,
        r.Description,
        r.MaxDurationMinutes,
        r.RequiresTicket,
        r.TicketRegex,
        r.RequiresJustification,
        r.RequiresApproval,
        r.AutoApproveMinSeniority
    FROM [jit].[Roles] r
    WHERE r.IsEnabled = 1
    AND EXISTS (
        -- Use eligibility check logic
        SELECT 1
        WHERE EXISTS (
            -- Explicit user override
            SELECT 1 FROM [jit].[User_To_Role_Eligibility] ue
            WHERE ue.UserId = @UserId AND ue.RoleId = r.RoleId
            AND (ue.ValidFromUtc IS NULL OR ue.ValidFromUtc <= GETUTCDATE())
            AND (ue.ValidToUtc IS NULL OR ue.ValidToUtc >= GETUTCDATE())
            AND ue.CanRequest = 1
        )
        OR EXISTS (
            -- Eligibility rules (simplified check - full logic in sp_User_Eligibility_Check)
            SELECT 1 FROM [jit].[Role_Eligibility_Rules] rer
            WHERE rer.RoleId = r.RoleId
            AND rer.CanRequest = 1
            AND (rer.ValidFromUtc IS NULL OR rer.ValidFromUtc <= GETUTCDATE())
            AND (rer.ValidToUtc IS NULL OR rer.ValidToUtc >= GETUTCDATE())
        )
    )
    ORDER BY r.RoleName;
    
    -- More accurate would be to call sp_User_Eligibility_Check for each role, but for performance
    -- this simplified version is used. For exact eligibility, use sp_User_Eligibility_Check before allowing request.
END
GO

PRINT 'Stored Procedure [jit].[sp_Role_ListRequestable] created successfully'
GO

