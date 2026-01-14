# SCD Type 2 Implementation Proposal

## Current State
- Dimension tables (Users, Roles) use natural keys as primary keys
- UPDATE operations overwrite existing data (no history)
- DELETE operations remove rows (data loss)
- No time-based tracking of dimension changes

## Proposed Changes

### 1. Dimension Table Schema Changes

#### Users Table
**Changes:**
- Add surrogate key: `UserDimensionKey` (BIGINT IDENTITY) - new primary key
- Change `UserId` from PRIMARY KEY to regular column (non-unique, since we'll have multiple versions)
- Add `StartDate` DATETIME2(7) NOT NULL - when this version became effective
- Add `EndDate` DATETIME2(7) NULL - when this version ended (NULL for current)
- Add `IsCurrent` BIT NOT NULL DEFAULT 1 - 1 for current version, 0 for historical
- Keep all existing columns

**New Primary Key:** `UserDimensionKey`
**Indexes:**
- Unique index on `(UserId, StartDate)` for point-in-time lookups
- Index on `(UserId, IsCurrent)` for current version lookups
- Index on `StartDate, EndDate` for time-range queries

#### Roles Table
**Changes:**
- Add surrogate key: `RoleDimensionKey` (BIGINT IDENTITY) - new primary key
- Change `RoleId` from PRIMARY KEY to regular column (non-unique)
- Add `StartDate` DATETIME2(7) NOT NULL
- Add `EndDate` DATETIME2(7) NULL
- Add `IsCurrent` BIT NOT NULL DEFAULT 1
- Keep all existing columns

**New Primary Key:** `RoleDimensionKey`
**Indexes:**
- Unique index on `(RoleId, StartDate)` for point-in-time lookups
- Index on `(RoleId, IsCurrent)` for current version lookups
- Index on `StartDate, EndDate` for time-range queries

### 2. ETL Procedure Changes

#### LSN to DateTime Conversion
For StartDate/EndDate, we need the transaction commit time. Options:

**Option 1: Use sys.fn_cdc_map_lsn_to_time (Recommended)**
- Converts LSN to transaction commit datetime
- Requires cross-database access (ETL in reporting DB, function in operational DB)
- Implementation: Use linked server or cross-database query
- Example: `[OperationalDB].sys.fn_cdc_map_lsn_to_time(@LSN)`

**Option 2: Use UpdatedUtc from CDC change table**
- CDC change tables include all source columns (including `UpdatedUtc`)
- Uses the `UpdatedUtc` value from the source table
- Simpler (no cross-database access needed)
- Note: This is the application's timestamp, not the transaction commit time

**Recommendation:** Use Option 1 (LSN to datetime) for true transaction time tracking.

#### INSERT Logic
```sql
-- INSERT new dimension row
INSERT INTO [reporting].[Users] (UserId, ..., StartDate, EndDate, IsCurrent)
SELECT UserId, ..., 
    sys.fn_cdc_map_lsn_to_time(__$start_lsn) AS StartDate,
    NULL AS EndDate,
    1 AS IsCurrent
FROM cdc.fn_cdc_get_all_changes_jit_Users(@FromLSN, @ToLSN, 'all')
WHERE __$operation = 2
```

#### UPDATE Logic
```sql
-- Step 1: Close old current row
UPDATE r
SET EndDate = sys.fn_cdc_map_lsn_to_time(s.__$start_lsn),
    IsCurrent = 0
FROM [reporting].[Users] r
INNER JOIN cdc.fn_cdc_get_all_changes_jit_Users(@FromLSN, @ToLSN, 'all') s
    ON r.UserId = s.UserId AND r.IsCurrent = 1
WHERE s.__$operation = 4;

-- Step 2: Insert new current row
INSERT INTO [reporting].[Users] (UserId, ..., StartDate, EndDate, IsCurrent)
SELECT UserId, ...,
    sys.fn_cdc_map_lsn_to_time(__$start_lsn) AS StartDate,
    NULL AS EndDate,
    1 AS IsCurrent
FROM cdc.fn_cdc_get_all_changes_jit_Users(@FromLSN, @ToLSN, 'all')
WHERE __$operation = 4
```

#### DELETE Logic
```sql
-- Soft delete: Close current row, don't delete
UPDATE r
SET EndDate = sys.fn_cdc_map_lsn_to_time(s.__$start_lsn),
    IsCurrent = 0
FROM [reporting].[Users] r
INNER JOIN cdc.fn_cdc_get_all_changes_jit_Users(@FromLSN, @ToLSN, 'all') s
    ON r.UserId = s.UserId AND r.IsCurrent = 1
WHERE s.__$operation = 1
```

### 3. Fact Table Considerations

#### Current Fact Tables
Fact tables (Requests, Grants, Approvals, etc.) currently reference dimension natural keys (UserId, RoleId).

**Selected Approach: Option B - Add Dimension Surrogate Keys**

**Changes:**
- Add dimension surrogate keys to fact tables for proper star schema design
- ETL procedures will resolve dimension keys at load time using point-in-time lookups
- Better performance for reporting queries (direct joins on integer keys)
- Standard data warehouse pattern

**Fact Table Changes:**

1. **Requests Table:**
   - Add `UserDimensionKey` BIGINT NULL - FK to Users dimension (at request creation time)
   - Keep `UserId` for reference (denormalized)

2. **Grants Table:**
   - Add `UserDimensionKey` BIGINT NULL - FK to Users dimension (at grant creation time)
   - Add `RoleDimensionKey` BIGINT NULL - FK to Roles dimension (at grant creation time)
   - Keep `UserId`, `RoleId` for reference

3. **Approvals Table:**
   - Add `ApproverUserDimensionKey` BIGINT NULL - FK to Users dimension (at approval time)
   - Keep `ApproverUserId` for reference

4. **Request_Roles Table:**
   - Add `RoleDimensionKey` BIGINT NULL - FK to Roles dimension (at request creation time)
   - Keep `RoleId` for reference

5. **AuditLog Table:**
   - Add `ActorUserDimensionKey` BIGINT NULL - FK to Users dimension (at event time)
   - Add `TargetUserDimensionKey` BIGINT NULL - FK to Users dimension (at event time)
   - Keep `ActorUserId`, `TargetUserId` for reference

**ETL Logic for Dimension Key Resolution:**
- When loading facts, perform point-in-time lookup to find the correct dimension key
- Example: For Requests.CreatedUtc, find Users dimension row where:
  - UserId matches
  - CreatedUtc >= StartDate
  - CreatedUtc < EndDate OR EndDate IS NULL

### 4. Index Strategy

#### Dimension Tables
- Primary key on surrogate key (UserDimensionKey, RoleDimensionKey)
- Unique index on (UserId, StartDate) to prevent overlaps
- Index on (UserId, IsCurrent) for current version lookups
- Index on (RoleId, IsCurrent) for current version lookups
- Index on StartDate, EndDate for time-range queries

#### Fact Tables (if using point-in-time joins)
- Consider adding indexes on date columns used in joins
- Example: Index on Requests.CreatedUtc for point-in-time User lookups

### 5. Query Patterns

#### Get Current Version
```sql
SELECT * FROM [reporting].[Users]
WHERE UserId = @UserId AND IsCurrent = 1
```

#### Get Version at Point in Time
```sql
SELECT * FROM [reporting].[Users]
WHERE UserId = @UserId
  AND @PointInTime >= StartDate
  AND (@PointInTime < EndDate OR EndDate IS NULL)
```

#### Join Fact to Dimension at Point in Time
```sql
SELECT r.*, u.DisplayName, u.Division
FROM [reporting].[Requests] r
INNER JOIN [reporting].[Users] u 
    ON r.UserId = u.UserId
    AND r.CreatedUtc >= u.StartDate
    AND (r.CreatedUtc < u.EndDate OR u.EndDate IS NULL)
```

## Implementation Impact

### Files to Modify
1. `schema/01_Create_Dimension_Tables.sql` - Add SCD Type 2 columns (surrogate keys, StartDate, EndDate, IsCurrent)
2. `schema/02_Create_Fact_Tables.sql` - Add dimension surrogate key columns
3. `schema/03_Create_Indexes.sql` - Update indexes for dimensions and fact tables
4. `etl/sp_Reporting_Sync_Users.sql` - Implement SCD Type 2 logic
5. `etl/sp_Reporting_Sync_Roles.sql` - Implement SCD Type 2 logic
6. `etl/sp_Reporting_Sync_Requests.sql` - Add dimension key resolution
7. `etl/sp_Reporting_Sync_Grants.sql` - Add dimension key resolution
8. `etl/sp_Reporting_Sync_Approvals.sql` - Add dimension key resolution
9. `etl/sp_Reporting_Sync_Request_Roles.sql` - Add dimension key resolution
10. `etl/sp_Reporting_Sync_AuditLog.sql` - Add dimension key resolution (optional)

### Considerations
1. **LSN to DateTime**: Need to handle cross-database access for `sys.fn_cdc_map_lsn_to_time`
   - Option: Use linked server
   - Option: Store datetime in a temp table and join
   - Option: Use CDC change table metadata (if available)
   
2. **Full Sync**: Need to handle initial load properly
   - First row for each UserId/RoleId: StartDate = CreatedUtc, IsCurrent = 1
   - Subsequent changes: Track through CDC changes

3. **Data Volume**: SCD Type 2 will increase dimension table size
   - Users: Each user update creates new row
   - Roles: Each role update creates new row
   - Consider: Index maintenance, query performance

4. **Backward Compatibility**: 
   - Queries using current dimension data need to filter by IsCurrent = 1
   - Point-in-time queries need date range filters

## Questions for Confirmation

1. **LSN to DateTime**: The `sys.fn_cdc_map_lsn_to_time` function requires access to the operational database. Should we:
   - Use a linked server reference?
   - Store the datetime in a staging table?
   - Use another approach?

2. **EndDate Handling**: Should EndDate be:
   - NULL for current rows (recommended)
   - Or set to a far future date (e.g., '9999-12-31')?

3. **Fact Table Joins**: Do you want to:
   - Keep natural keys in fact tables (simpler, current approach)
   - Add dimension surrogate keys to fact tables (more complex, better for star schema)

4. **Unique Constraint**: Should we enforce:
   - Only one current row per UserId/RoleId (IsCurrent = 1)
   - Or allow multiple (not recommended)?
