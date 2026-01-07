-- =============================================
-- SQL Agent Job: jit.Job_ExpireGrants
-- Expires grants automatically
-- Schedule: Every 5-15 minutes (configure in SQL Agent)
-- =============================================
-- Note: This is a template for creating the SQL Agent job
-- Execute this procedure as part of the job step

USE [DMAP_JIT_Permissions]
GO

-- Create a wrapper procedure that can be called by SQL Agent
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[sp_Job_ExpireGrants]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [jit].[sp_Job_ExpireGrants]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [jit].[sp_Job_ExpireGrants]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExpiredCount INT;
    
    EXEC [jit].[sp_Grant_Expire] @ExpiredCount OUTPUT;
    
    -- Log summary (optional)
    PRINT 'Expired ' + CAST(@ExpiredCount AS NVARCHAR(10)) + ' grant(s)';
END
GO

PRINT 'Wrapper procedure [jit].[sp_Job_ExpireGrants] created successfully'
GO

-- Instructions for creating SQL Agent Job:
-- 1. Open SQL Server Management Studio
-- 2. Go to SQL Server Agent > Jobs
-- 3. Right-click Jobs > New Job
-- 4. Name: "JIT - Expire Grants"
-- 5. Add Step:
--    - Type: Transact-SQL script (T-SQL)
--    - Command: EXEC [jit].[sp_Job_ExpireGrants]
-- 6. Schedule: Create new schedule
--    - Frequency: Occurs every 10 minutes (or desired interval)
--    - Start time: Current time or preferred start time

