-- =============================================
-- SQL Agent Job: Reporting ETL Sync
-- Runs ETL sync every 15 minutes
-- =============================================

USE [msdb]
GO

-- Delete job if it exists
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'JIT Reporting - ETL Sync')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = 'JIT Reporting - ETL Sync'
END
GO

-- Create job
EXEC msdb.dbo.sp_add_job
    @job_name = 'JIT Reporting - ETL Sync',
    @description = 'Syncs data from operational database to reporting database using CDC',
    @category_name = 'Database Maintenance',
    @owner_login_name = 'sa'
GO

-- Add job step
EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'JIT Reporting - ETL Sync',
    @step_name = 'Run ETL Sync',
    @subsystem = 'TSQL',
    @database_name = 'DMAP_JIT_Permissions_Reporting',
    @command = 'EXEC [reporting].[sp_Reporting_Sync_All] @FullSync = 0;',
    @retry_attempts = 3,
    @retry_interval = 5,
    @on_success_action = 1,  -- Quit with success
    @on_fail_action = 2  -- Quit with failure
GO

-- Create schedule (every 15 minutes)
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = 'JIT Reporting ETL Sync - Every 15 Minutes',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @freq_subday_type = 4,  -- Minutes
    @freq_subday_interval = 15,
    @active_start_time = 0  -- Start at 00:00:00
GO

-- Attach schedule to job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = 'JIT Reporting - ETL Sync',
    @schedule_name = 'JIT Reporting ETL Sync - Every 15 Minutes'
GO

-- Add job to local server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = 'JIT Reporting - ETL Sync',
    @server_name = '(local)'
GO

PRINT 'SQL Agent Job "JIT Reporting - ETL Sync" created successfully'
GO
