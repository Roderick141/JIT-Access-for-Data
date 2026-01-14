-- =============================================
-- SQL Agent Job: Reporting Archive Data
-- Runs archive process monthly (first day of month)
-- =============================================

USE [msdb]
GO

-- Delete job if it exists
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'JIT Reporting - Archive Old Data')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = 'JIT Reporting - Archive Old Data'
END
GO

-- Create job
EXEC msdb.dbo.sp_add_job
    @job_name = 'JIT Reporting - Archive Old Data',
    @description = 'Archives data older than retention period from operational to reporting database',
    @category_name = 'Database Maintenance',
    @owner_login_name = 'sa'
GO

-- Add job step
EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'JIT Reporting - Archive Old Data',
    @step_name = 'Run Archive Process',
    @subsystem = 'TSQL',
    @database_name = 'DMAP_JIT_Permissions',
    @command = 'EXEC [reporting].[sp_Reporting_Archive_OldData] @RetentionDays = 90, @DryRun = 0;',
    @retry_attempts = 2,
    @retry_interval = 10,
    @on_success_action = 1,  -- Quit with success
    @on_fail_action = 2  -- Quit with failure
GO

-- Create schedule (first day of month at 2:00 AM)
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = 'JIT Reporting Archive - Monthly',
    @freq_type = 16,  -- Monthly
    @freq_interval = 1,  -- First day of month
    @freq_recurrence_factor = 1,
    @active_start_time = 20000  -- Start at 02:00:00
GO

-- Attach schedule to job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = 'JIT Reporting - Archive Old Data',
    @schedule_name = 'JIT Reporting Archive - Monthly'
GO

-- Add job to local server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = 'JIT Reporting - Archive Old Data',
    @server_name = '(local)'
GO

PRINT 'SQL Agent Job "JIT Reporting - Archive Old Data" created successfully'
GO
