# JIT Access Framework - Deployment Guide

## Overview

This directory contains scripts to deploy and manage the JIT Access Framework database objects.

## Quick Start

### Full Deployment
Run the master deployment script to create everything:
```bash
sqlcmd -S YourServerName -d DMAP_JIT_Permissions -i "01_Deploy_Everything.sql"
```

### Cleanup (Remove Everything)
Run the cleanup script to remove all objects (WARNING: Deletes all data!):
```bash
sqlcmd -S YourServerName -d DMAP_JIT_Permissions -i "02_Cleanup_Everything.sql"
```

## Scripts

### `01_Deploy_Everything.sql`
Master deployment script that:
1. Creates all database tables (schema)
2. Creates all stored procedures
3. Inserts test data (development)
4. Backfills `UserContextVersionId` columns and enforces context integrity constraints

**Usage:**
```sql
-- In SSMS with SQLCMD mode enabled:
:r "database\01_Deploy_Everything.sql"

-- Or via sqlcmd:
sqlcmd -S ServerName -d DMAP_JIT_Permissions -i "database\01_Deploy_Everything.sql"
```

**Note:** The script currently includes test data insertion for development workflows.

### `02_Cleanup_Everything.sql`
Cleanup script that removes all JIT Framework objects. **WARNING: This deletes all data!**

**Usage:**
```sql
-- In SSMS with SQLCMD mode enabled:
:r "database\02_Cleanup_Everything.sql"

-- Or via sqlcmd:
sqlcmd -S ServerName -d DMAP_JIT_Permissions -i "database\02_Cleanup_Everything.sql"
```

## Deployment Order

The deployment follows this order:
1. **Schema Creation** (`schema/99_Create_All_Tables.sql`)
   - Creates `jit` schema
   - Creates all tables in dependency order
   
2. **Stored Procedures** (`procedures/99_Create_All_Procedures.sql`)
   - Creates all stored procedures in dependency order
   
3. **Test Data** (optional, `test_data/99_Insert_All_Test_Data.sql`)
   - Inserts sample data for testing

4. **Post-Deploy Backfill** (`03_Backfill_UserContextVersionIds.sql`)
   - Backfills temporal user context references into workflow/audit rows
   - Enforces integrity constraints for required context mappings

## Cleanup Order

The cleanup follows reverse dependency order:
1. **Drop Stored Procedures** (no dependencies on tables for dropping)
2. **Drop Tables** (in reverse dependency order)
   - Workflow tables first (AuditLog, Grant_DBRole_Assignments, etc.)
   - Then eligibility/team tables
   - Then role mapping tables
   - Then `User_Context_Versions`
   - Finally `Users` table
3. **Drop Schema** (optional)

## Prerequisites

1. **Database exists**: The database `DMAP_JIT_Permissions` must exist
   ```sql
   CREATE DATABASE [DMAP_JIT_Permissions]
   ```

2. **Permissions**: User needs:
   - CREATE TABLE permission
   - CREATE PROCEDURE permission
   - ALTER SCHEMA permission
   - If including test data, INSERT permission

3. **SQLCMD mode**: If using SSMS, enable SQLCMD mode:
   - Query menu → SQLCMD Mode

## Manual Deployment

If you prefer to deploy components individually:

### 1. Schema Only
```sql
:r "schema\99_Create_All_Tables.sql"
```

### 2. Procedures Only
```sql
:r "procedures\99_Create_All_Procedures.sql"
```

### 3. Test Data Only
```sql
:r "test_data\99_Insert_All_Test_Data.sql"
```

### 4. Backfill Context IDs / Enforce Integrity
```sql
:r "03_Backfill_UserContextVersionIds.sql"
```

## Troubleshooting

### "Invalid object name" errors
- Ensure you're connected to the correct database (`DMAP_JIT_Permissions`)
- Check that previous steps completed successfully

### Foreign key constraint errors during cleanup
- Run cleanup script sections in order (procedures first, then tables)
- Tables are dropped in reverse dependency order to avoid constraint violations

### SQLCMD ":r" command not recognized
- Enable SQLCMD mode in SSMS (Query → SQLCMD Mode)
- Or use `sqlcmd` command-line tool instead

## Post-Deployment Setup

After deployment:

1. **Set up admin users:**
   ```sql
   UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\adminuser';
   ```

2. **Configure service account:**
   ```sql
   CREATE LOGIN [JIT_ServiceAccount] WITH PASSWORD = 'YourStrongPassword123!';
   USE [DMAP_JIT_Permissions];
   CREATE USER [JIT_ServiceAccount] FOR LOGIN [JIT_ServiceAccount];
   GRANT EXECUTE ON SCHEMA::jit TO [JIT_ServiceAccount];
   GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::jit TO [JIT_ServiceAccount];
   ```

3. **Create SQL Agent job** (optional, for automatic grant expiration):
   - See `jobs/job_ExpireGrants.sql` for instructions

