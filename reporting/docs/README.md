# JIT Framework Reporting & Historical Data Storage

## Overview

This module implements **Option 2: Separate Reporting Database with Change Data Capture (CDC)** to provide scalable, non-blocking reporting capabilities for the JIT Access Framework.

## Architecture

### Databases

- **Operational Database**: `DMAP_JIT_Permissions`
  - Contains current/active data
  - Optimized for transaction processing
  - Data older than 90 days is archived to reporting database
  
- **Reporting Database**: `DMAP_JIT_Permissions_Reporting`
  - Contains full historical data (5+ years retention)
  - Optimized for analytical queries
  - Denormalized structure for reporting performance
  - Used by Power BI and ad-hoc reporting

### Data Flow

```
Operational DB (DMAP_JIT_Permissions)
    │
    ├─→ CDC Capture (Real-time)
    │       │
    │       └─→ ETL Process (Every 15 minutes)
    │               │
    │               └─→ Reporting DB (DMAP_JIT_Permissions_Reporting)
    │
    └─→ Archive Process (Monthly)
            │
            └─→ Moves data older than 90 days to Reporting DB only
```

## Components

### 1. CDC (Change Data Capture)
- **Location**: `reporting/cdc/`
- **Purpose**: Enables real-time tracking of changes to operational tables
- **Tables Tracked**:
  - `jit.Users`
  - `jit.Roles`
  - `jit.Requests`
  - `jit.Grants`
  - `jit.Approvals`
  - `jit.Request_Roles`
  - `jit.AuditLog` (copy-based, not CDC)

### 2. ETL (Extract, Transform, Load)
- **Location**: `reporting/etl/`
- **Purpose**: Syncs CDC changes to reporting database
- **Frequency**: Every 15 minutes (configurable)
- **Method**: Processes CDC change tables by operation type (INSERT/UPDATE/DELETE)

### 3. Archive Process
- **Location**: `reporting/archive/`
- **Purpose**: Moves old data from operational DB to reporting DB
- **Frequency**: Monthly (configurable)
- **Retention**: Keeps 90 days in operational DB

### 4. Reporting Schema
- **Location**: `reporting/schema/`
- **Purpose**: Defines reporting database structure
- **Design**: Denormalized fact tables optimized for Power BI

## Setup Instructions

### Prerequisites

1. **SQL Server Enterprise Edition** (CDC requires Enterprise Edition)
2. **Operational database** (`DMAP_JIT_Permissions`) must be deployed and running
3. **Service account** with appropriate permissions (see permissions section)

### Step 1: Create Reporting Database

```sql
CREATE DATABASE [DMAP_JIT_Permissions_Reporting]
  COLLATE SQL_Latin1_General_CP1_CI_AS;
GO

ALTER DATABASE [DMAP_JIT_Permissions_Reporting] 
  SET RECOVERY SIMPLE;  -- Reporting DB doesn't need full recovery
GO
```

### Step 2: Enable CDC on Operational Database

Run the scripts in `reporting/cdc/` in order:

1. `00_Enable_CDC_Database.sql` - Enable CDC at database level
2. `01_Enable_CDC_Tables.sql` - Enable CDC on each table

**Note**: CDC requires SQL Server Enterprise Edition.

### Step 3: Deploy Reporting Database Schema

Run the scripts in `reporting/schema/` in order:

1. `00_Create_Reporting_Schema.sql` - Create schema
2. `01_Create_Dimension_Tables.sql` - Create dimension tables
3. `02_Create_Fact_Tables.sql` - Create fact tables
4. `03_Create_Indexes.sql` - Create reporting indexes
5. `99_Create_All_Reporting_Schema.sql` - Master script (runs all above)

### Step 4: Deploy ETL Procedures

Deploy all stored procedures in `reporting/etl/`:

- `sp_Reporting_Sync_Users.sql`
- `sp_Reporting_Sync_Roles.sql`
- `sp_Reporting_Sync_Requests.sql`
- `sp_Reporting_Sync_Grants.sql`
- `sp_Reporting_Sync_Approvals.sql`
- `sp_Reporting_Sync_Request_Roles.sql`
- `sp_Reporting_Sync_AuditLog.sql` (copy-based, not CDC)
- `sp_Reporting_Sync_All.sql` (master procedure)

### Step 5: Initial Data Load

After deploying all components, run the initial data load:

```sql
USE [DMAP_JIT_Permissions_Reporting];
GO

-- Load all existing data from operational DB
EXEC [reporting].[sp_Reporting_Sync_All] @FullSync = 1;
GO
```

### Step 6: Deploy Archive Procedures

Deploy archive procedures in `reporting/archive/`:

- `sp_Reporting_Archive_OldData.sql` - Archives data older than retention period

### Step 7: Create SQL Agent Jobs

Deploy SQL Agent jobs in `reporting/jobs/`:

1. `job_Reporting_ETL_Sync.sql` - Runs ETL sync every 15 minutes
2. `job_Reporting_Archive_Data.sql` - Runs archive process monthly
3. `job_Reporting_Maintain_CDC.sql` - Cleans up old CDC data

### Step 8: Configure and Test

1. **Verify CDC is capturing changes**:
   ```sql
   USE [DMAP_JIT_Permissions];
   SELECT * FROM cdc.dbo_cdc_jobs;
   ```

2. **Test ETL sync manually**:
   ```sql
   USE [DMAP_JIT_Permissions_Reporting];
   EXEC [reporting].[sp_Reporting_Sync_All];
   ```

3. **Monitor first few ETL runs**:
   - Check SQL Agent job history
   - Verify data appears in reporting tables
   - Check for errors in job output

## Permissions Required

### Service Account (for ETL processes)

The service account needs the following permissions:

```sql
-- On Operational Database (DMAP_JIT_Permissions)
USE [DMAP_JIT_Permissions];
GO

-- Read access to source tables
GRANT SELECT ON SCHEMA::[jit] TO [YourServiceAccount];

-- Read access to CDC tables (automatically granted with db_datareader)
GRANT SELECT ON SCHEMA::[cdc] TO [YourServiceAccount];
GO

-- On Reporting Database (DMAP_JIT_Permissions_Reporting)
USE [DMAP_JIT_Permissions_Reporting];
GO

-- Full access to reporting schema
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[reporting] TO [YourServiceAccount];
GRANT EXECUTE ON SCHEMA::[reporting] TO [YourServiceAccount];
GO
```

## CDC Details

### How CDC Works

1. **CDC Enablement**: When CDC is enabled on a table, SQL Server creates:
   - A change table in the `cdc` schema (e.g., `cdc.jit_Users_CT`)
   - Captures INSERT, UPDATE, DELETE operations
   - Tracks metadata (operation type, transaction LSN, etc.)

2. **Change Table Structure**:
   - All columns from source table
   - `__$start_lsn` - Log Sequence Number (transaction identifier)
   - `__$seqval` - Sequence value within transaction
   - `__$operation` - Operation type (1=DELETE, 2=INSERT, 3=UPDATE before, 4=UPDATE after)
   - `__$update_mask` - Bitmask indicating which columns changed (UPDATE only)

3. **ETL Process**:
   - Queries CDC change tables using `cdc.fn_cdc_get_all_changes_*` or `cdc.fn_cdc_get_net_changes_*` functions
   - Processes changes by operation type:
     - **INSERT (2)**: Insert new row into reporting table
     - **UPDATE (4)**: Update existing row in reporting table
     - **DELETE (1)**: Delete row from reporting table (or mark as deleted)
   - Tracks last processed LSN to avoid reprocessing

### CDC Functions

- `cdc.fn_cdc_get_all_changes_<capture_instance>` - Gets all changes in a range
- `cdc.fn_cdc_get_net_changes_<capture_instance>` - Gets net changes (last state only)
- `sys.fn_cdc_get_min_lsn('<capture_instance>')` - Gets minimum available LSN
- `sys.fn_cdc_get_max_lsn()` - Gets maximum LSN
- `sys.fn_cdc_map_time_to_lsn('largest less than or equal', @Time)` - Maps time to LSN

### CDC Maintenance

CDC change tables grow over time. Maintenance is handled by:

1. **Automatic Cleanup Job**: `cdc.<database>_cleanup` (created automatically)
   - Default retention: 3 days (4320 minutes)
   - Can be adjusted based on ETL frequency

2. **Manual Cleanup** (if needed):
   ```sql
   EXEC sys.sp_cdc_cleanup_change_table
       @capture_instance = 'jit_Users',
       @low_lsn = <low_lsn>,
       @threshold = 5000;
   ```

## ETL Process Details

### ETL Sync Method (Process by Operation Type)

The ETL process uses CDC's operation type tracking:

1. **Get Change Window**: 
   - Determine LSN range since last sync
   - Use `cdc.fn_cdc_get_all_changes_*` to get all changes

2. **Process by Operation**:
   - **INSERT (operation = 2)**: Insert new row
   - **UPDATE (operation = 4)**: Update existing row (by primary key)
   - **DELETE (operation = 1)**: Delete row (or soft delete)

3. **Update Sync Metadata**: 
   - Track last processed LSN
   - Store in `reporting.CDC_SyncState` table

### Why Not Upsert (MERGE)?

While upsert (MERGE) might seem simpler, processing by operation type is better for CDC because:

- ✅ **CDC already tracks operation types** - No need to infer INSERT vs UPDATE
- ✅ **Handles DELETEs correctly** - MERGE doesn't handle deletes
- ✅ **More efficient** - No complex matching logic needed
- ✅ **Standard CDC pattern** - Aligns with Microsoft best practices
- ✅ **Better for audit trails** - Preserves operation semantics

### ETL Frequency

- **Default**: Every 15 minutes
- **Configurable**: Adjust SQL Agent job schedule
- **Latency**: Near real-time (15 minute delay maximum)

## Archive Process Details

### Archive Strategy

1. **Retention Policy**: Keep 90 days of data in operational DB
2. **Archive Frequency**: Monthly (first day of month)
3. **Archive Process**:
   - Identifies data older than 90 days
   - Verifies data exists in reporting DB (from CDC sync)
   - Deletes old data from operational DB
   - Leaves reporting DB unchanged (already has full history)

### Tables Archived

- `jit.Requests` (archived by `CreatedUtc`)
- `jit.Grants` (archived by `ValidFromUtc`)
- `jit.Approvals` (archived by `DecisionUtc`)
- `jit.AuditLog` (archived by `EventUtc`)

**Note**: `Users` and `Roles` are NOT archived (dimension tables, keep current in operational DB).

### Archive Safety

- Archive process verifies data exists in reporting DB before deletion
- Uses transactions for atomic operations
- Can be run manually for testing
- Logs all archive operations

## Monitoring and Troubleshooting

### Monitoring Queries

**Check CDC Status**:
```sql
USE [DMAP_JIT_Permissions];
SELECT * FROM cdc.dbo_cdc_jobs;
SELECT * FROM cdc.change_tables;
```

**Check ETL Sync Status**:
```sql
USE [DMAP_JIT_Permissions_Reporting];
SELECT * FROM [reporting].[CDC_SyncState]
ORDER BY TableName, LastSyncLSN;
```

**Check Data Counts**:
```sql
USE [DMAP_JIT_Permissions_Reporting];
SELECT 'Requests' AS TableName, COUNT(*) AS Count FROM [reporting].[Requests]
UNION ALL
SELECT 'Grants', COUNT(*) FROM [reporting].[Grants]
UNION ALL
SELECT 'AuditLog', COUNT(*) FROM [reporting].[AuditLog];
```

**Compare Operational vs Reporting**:
```sql
-- Operational
USE [DMAP_JIT_Permissions];
SELECT COUNT(*) AS OperationalCount FROM [jit].[Requests];

-- Reporting
USE [DMAP_JIT_Permissions_Reporting];
SELECT COUNT(*) AS ReportingCount FROM [reporting].[Requests];
```

### Common Issues

1. **CDC Not Capturing Changes**
   - Verify CDC is enabled: `SELECT is_cdc_enabled FROM sys.databases WHERE name = 'DMAP_JIT_Permissions'`
   - Check CDC jobs are running: `SELECT * FROM cdc.dbo_cdc_jobs`
   - Verify table CDC status: `SELECT * FROM cdc.change_tables`

2. **ETL Sync Failing**
   - Check SQL Agent job history
   - Verify service account permissions
   - Check for constraint violations in reporting tables
   - Verify CDC change tables have data

3. **Data Not Appearing in Reporting DB**
   - Run ETL sync manually and check for errors
   - Verify CDC is capturing changes
   - Check sync state table for last processed LSN
   - Compare row counts between operational and reporting

4. **Performance Issues**
   - Check CDC change table sizes (may need cleanup)
   - Verify indexes exist on reporting tables
   - Consider increasing ETL frequency if change volume is high
   - Monitor CDC job performance

### Logging

All ETL and archive procedures log operations to:
- `reporting.ETL_Log` - ETL operation logs
- SQL Agent job history (for scheduled jobs)

## Power BI Integration

### Connection String

```
Server=YourServer;Database=DMAP_JIT_Permissions_Reporting;Integrated Security=True;
```

### Recommended Data Model

The reporting schema is designed for Power BI with:
- Denormalized fact tables (fast queries)
- Dimension tables for slicing/dicing
- Optimized indexes for common query patterns

### Example Power BI Queries

**Total Requests by Month**:
```sql
SELECT 
    YEAR(CreatedUtc) AS Year,
    MONTH(CreatedUtc) AS Month,
    COUNT(*) AS RequestCount
FROM [reporting].[Requests]
GROUP BY YEAR(CreatedUtc), MONTH(CreatedUtc)
ORDER BY Year, Month;
```

**Active Grants by Role**:
```sql
SELECT 
    r.RoleName,
    COUNT(*) AS ActiveGrantCount
FROM [reporting].[Grants] g
INNER JOIN [reporting].[Roles] r ON g.RoleId = r.RoleId
WHERE g.Status = 'Active'
GROUP BY r.RoleName
ORDER BY ActiveGrantCount DESC;
```

## Maintenance Tasks

### Daily
- Monitor ETL job success (SQL Agent job history)
- Check for ETL errors in `reporting.ETL_Log`

### Weekly
- Compare row counts between operational and reporting DBs
- Review CDC change table sizes
- Check CDC cleanup job is running

### Monthly
- Review archive job execution
- Verify data retention policies
- Check reporting database size and growth
- Review index maintenance needs

### Quarterly
- Review and optimize reporting queries
- Update documentation as needed
- Review CDC retention settings

## Backup Strategy

### Operational Database
- Full backups: Daily
- Transaction log backups: Every 15 minutes (or as needed)

### Reporting Database
- Full backups: Weekly (or as needed based on change frequency)
- Since it's SIMPLE recovery model, transaction log backups not needed

## Security Considerations

1. **Service Account**: Use dedicated service account with minimal required permissions
2. **Network Security**: Reporting DB should be on same network or use secure connections
3. **Data Access**: Reporting DB access should be restricted to reporting users/service accounts
4. **Audit**: All ETL operations are logged in `reporting.ETL_Log`

## References

- [SQL Server Change Data Capture (CDC)](https://docs.microsoft.com/sql/relational-databases/track-changes/about-change-data-capture-sql-server)
- [CDC Functions](https://docs.microsoft.com/sql/relational-databases/system-functions/change-data-capture-functions-transact-sql)
- [CDC Best Practices](https://docs.microsoft.com/sql/relational-databases/track-changes/administer-and-monitor-change-data-capture-sql-server)
