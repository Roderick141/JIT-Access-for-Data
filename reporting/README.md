# JIT Framework Reporting Module

This module implements **Option 2: Separate Reporting Database with Change Data Capture (CDC)** for scalable, non-blocking reporting capabilities.

## Quick Start

1. **Read the documentation**: Start with `docs/README.md` for comprehensive overview
2. **Follow the setup guide**: See `docs/SETUP_GUIDE.md` for step-by-step setup instructions
3. **Review architecture**: See `docs/README.md` for architecture and design decisions

## Folder Structure

```
reporting/
├── docs/                    # Documentation
│   ├── README.md           # Comprehensive documentation
│   └── SETUP_GUIDE.md      # Step-by-step setup guide
├── schema/                  # Reporting database schema
│   ├── 00_Create_Reporting_Schema.sql
│   ├── 00a_Create_Supporting_Tables.sql
│   ├── 01_Create_Dimension_Tables.sql
│   ├── 02_Create_Fact_Tables.sql
│   ├── 03_Create_Indexes.sql
│   └── 99_Create_All_Reporting_Schema.sql
├── cdc/                     # CDC enablement scripts
│   ├── 00_Enable_CDC_Database.sql
│   └── 01_Enable_CDC_Tables.sql
├── etl/                     # ETL stored procedures
│   ├── sp_Reporting_Helper_LogETL.sql
│   ├── sp_Reporting_Sync_Users.sql
│   ├── sp_Reporting_Sync_Roles.sql
│   ├── sp_Reporting_Sync_Requests.sql
│   ├── sp_Reporting_Sync_Grants.sql
│   ├── sp_Reporting_Sync_Approvals.sql
│   ├── sp_Reporting_Sync_Request_Roles.sql
│   ├── sp_Reporting_Sync_AuditLog.sql
│   └── sp_Reporting_Sync_All.sql
├── archive/                 # Archive procedures
│   └── sp_Reporting_Archive_OldData.sql
└── jobs/                    # SQL Agent jobs
    ├── job_Reporting_ETL_Sync.sql
    └── job_Reporting_Archive_Data.sql
```

## Key Features

- **Change Data Capture (CDC)**: Real-time change tracking from operational database
- **Incremental ETL**: Efficient sync using CDC change tables
- **Archive Process**: Moves old data from operational to reporting database
- **Non-blocking**: Reporting queries don't impact operational performance
- **Power BI Ready**: Optimized schema for Power BI connectivity

## Requirements

- SQL Server Enterprise Edition (CDC requires Enterprise)
- Operational database (`DMAP_JIT_Permissions`) must be deployed
- SQL Server Agent must be running

## Documentation

- **`docs/README.md`**: Comprehensive documentation covering architecture, CDC details, ETL process, archive process, monitoring, troubleshooting, and Power BI integration
- **`docs/SETUP_GUIDE.md`**: Step-by-step setup instructions

## Implementation Notes

### ETL Sync Method

The ETL process uses **process-by-operation-type** (not upsert/MERGE) because:
- CDC already tracks operation types (INSERT/UPDATE/DELETE)
- Handles DELETEs correctly
- More efficient than MERGE
- Standard CDC pattern

### Data Flow

1. **CDC Capture**: Operational DB changes are captured in CDC change tables
2. **ETL Sync**: Every 15 minutes, changes are synced to reporting DB
3. **Archive**: Monthly, data older than 90 days is moved from operational to reporting DB only

### Tables Tracked

- **Dimension Tables**: Users, Roles (current state)
- **Fact Tables**: Requests, Grants, Approvals, Request_Roles, AuditLog (full history)

## Support

For issues or questions, refer to:
- Troubleshooting section in `docs/README.md`
- Setup guide for common setup issues
- SQL Server CDC documentation
