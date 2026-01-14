# Reporting Database Setup Guide

## Prerequisites

1. **SQL Server Enterprise Edition** (CDC requires Enterprise Edition)
2. **Operational database** (`DMAP_JIT_Permissions`) must be deployed and running
3. **Service account** with appropriate permissions (see Permissions section)
4. **SQL Server Agent** must be running

## Step-by-Step Setup

### Step 1: Create Reporting Database

```sql
-- Create the reporting database
CREATE DATABASE [DMAP_JIT_Permissions_Reporting]
  COLLATE SQL_Latin1_General_CP1_CI_AS;
GO

-- Set recovery model to SIMPLE (reporting DB doesn't need full recovery)
ALTER DATABASE [DMAP_JIT_Permissions_Reporting] 
  SET RECOVERY SIMPLE;
GO
```

### Step 2: Enable CDC on Operational Database

1. **Enable CDC at database level**:
   ```sql
   USE [DMAP_JIT_Permissions];
   GO
   
   -- Run: reporting/cdc/00_Enable_CDC_Database.sql
   ```

2. **Enable CDC on tables**:
   ```sql
   USE [DMAP_JIT_Permissions];
   GO
   
   -- Run: reporting/cdc/01_Enable_CDC_Tables.sql
   ```

3. **Verify CDC is enabled**:
   ```sql
   USE [DMAP_JIT_Permissions];
   SELECT * FROM cdc.change_tables;
   ```

### Step 3: Deploy Reporting Database Schema

```sql
USE [DMAP_JIT_Permissions_Reporting];
GO

-- Run master script: reporting/schema/99_Create_All_Reporting_Schema.sql
-- Or run individual scripts in order:
--   00_Create_Reporting_Schema.sql
--   00a_Create_Supporting_Tables.sql
--   01_Create_Dimension_Tables.sql
--   02_Create_Fact_Tables.sql
--   03_Create_Indexes.sql
```

### Step 4: Deploy ETL Procedures

Deploy all procedures in `reporting/etl/` to the **reporting database**:

1. `sp_Reporting_Helper_LogETL.sql`
2. `sp_Reporting_Sync_Users.sql`
3. `sp_Reporting_Sync_Roles.sql`
4. `sp_Reporting_Sync_Requests.sql`
5. `sp_Reporting_Sync_Grants.sql`
6. `sp_Reporting_Sync_Approvals.sql`
7. `sp_Reporting_Sync_Request_Roles.sql`
8. `sp_Reporting_Sync_AuditLog.sql`
9. `sp_Reporting_Sync_All.sql`

**Note**: All ETL procedures go in the **reporting database**.

### Step 5: Deploy Archive Procedure

Deploy the archive procedure to the **operational database**:

```sql
USE [DMAP_JIT_Permissions];
GO

-- Run: reporting/archive/sp_Reporting_Archive_OldData.sql
```

**Note**: Archive procedure goes in the **operational database** (it needs access to both databases).

### Step 6: Set Up Permissions

Grant necessary permissions to your service account:

```sql
-- On Operational Database
USE [DMAP_JIT_Permissions];
GO

GRANT SELECT ON SCHEMA::[jit] TO [YourServiceAccount];
GRANT SELECT ON SCHEMA::[cdc] TO [YourServiceAccount];
GO

-- On Reporting Database
USE [DMAP_JIT_Permissions_Reporting];
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[reporting] TO [YourServiceAccount];
GRANT EXECUTE ON SCHEMA::[reporting] TO [YourServiceAccount];
GO

-- For archive procedure (on operational DB)
USE [DMAP_JIT_Permissions];
GO

GRANT EXECUTE ON SCHEMA::[reporting] TO [YourServiceAccount];
GO
```

### Step 7: Initial Data Load

Perform initial full sync to load existing data:

```sql
USE [DMAP_JIT_Permissions_Reporting];
GO

-- Full sync loads all existing data
EXEC [reporting].[sp_Reporting_Sync_All] @FullSync = 1;
GO

-- Verify data was loaded
SELECT 
    'Users' AS TableName, COUNT(*) AS Count FROM [reporting].[Users]
UNION ALL
SELECT 'Roles', COUNT(*) FROM [reporting].[Roles]
UNION ALL
SELECT 'Requests', COUNT(*) FROM [reporting].[Requests]
UNION ALL
SELECT 'Grants', COUNT(*) FROM [reporting].[Grants]
UNION ALL
SELECT 'Approvals', COUNT(*) FROM [reporting].[Approvals]
UNION ALL
SELECT 'AuditLog', COUNT(*) FROM [reporting].[AuditLog];
```

### Step 8: Create SQL Agent Jobs

1. **ETL Sync Job** (runs every 15 minutes):
   ```sql
   -- Run: reporting/jobs/job_Reporting_ETL_Sync.sql
   ```

2. **Archive Job** (runs monthly):
   ```sql
   -- Run: reporting/jobs/job_Reporting_Archive_Data.sql
   ```

3. **Verify jobs were created**:
   ```sql
   USE [msdb];
   SELECT name, enabled, date_created 
   FROM sysjobs 
   WHERE name LIKE 'JIT Reporting%';
   ```

4. **Start the ETL job** (archive job runs monthly, so leave it):
   ```sql
   USE [msdb];
   EXEC sp_start_job @job_name = 'JIT Reporting - ETL Sync';
   ```

### Step 9: Verify Setup

1. **Check CDC is capturing changes**:
   ```sql
   USE [DMAP_JIT_Permissions];
   SELECT * FROM cdc.dbo_cdc_jobs;
   ```

2. **Run manual ETL sync**:
   ```sql
   USE [DMAP_JIT_Permissions_Reporting];
   EXEC [reporting].[sp_Reporting_Sync_All];
   ```

3. **Check ETL logs**:
   ```sql
   USE [DMAP_JIT_Permissions_Reporting];
   SELECT TOP 20 * 
   FROM [reporting].[ETL_Log]
   ORDER BY LogUtc DESC;
   ```

4. **Check sync state**:
   ```sql
   USE [DMAP_JIT_Permissions_Reporting];
   SELECT * FROM [reporting].[CDC_SyncState];
   ```

5. **Compare row counts** (after some operations):
   ```sql
   -- Operational
   USE [DMAP_JIT_Permissions];
   SELECT COUNT(*) AS OpCount FROM [jit].[Requests];
   
   -- Reporting
   USE [DMAP_JIT_Permissions_Reporting];
   SELECT COUNT(*) AS RepCount FROM [reporting].[Requests];
   ```

## Troubleshooting

### CDC Not Enabled

**Error**: CDC functions return NULL or errors

**Solution**: Verify Enterprise Edition and CDC enablement:
```sql
SELECT is_cdc_enabled FROM sys.databases WHERE name = 'DMAP_JIT_Permissions';
SELECT * FROM cdc.change_tables;
```

### ETL Sync Fails

**Check**:
1. Service account permissions
2. ETL log table for errors: `SELECT * FROM [reporting].[ETL_Log] WHERE Status = 'Error'`
3. CDC change tables have data
4. Both databases are accessible

### Archive Process Fails

**Common causes**:
- Data doesn't exist in reporting DB (verify with sync first)
- Foreign key constraints (check cascade settings)
- Permissions issues

**Solution**: Run with `@DryRun = 1` first to see what would be archived:
```sql
EXEC [reporting].[sp_Reporting_Archive_OldData] @RetentionDays = 90, @DryRun = 1;
```

## Maintenance

### Daily
- Monitor ETL job success (SQL Agent job history)
- Check ETL logs for errors

### Weekly
- Compare row counts between operational and reporting
- Review CDC change table sizes

### Monthly
- Review archive job execution
- Verify data retention policies

### As Needed
- Adjust CDC retention (default 3 days)
- Optimize indexes on reporting tables
- Review and clean up ETL logs (older than 90 days)

## Next Steps

After setup is complete:
1. Connect Power BI to `DMAP_JIT_Permissions_Reporting` database
2. Create data models using the reporting schema
3. Build reports and dashboards
4. Monitor ETL sync performance
5. Adjust sync frequency if needed (default: 15 minutes)
