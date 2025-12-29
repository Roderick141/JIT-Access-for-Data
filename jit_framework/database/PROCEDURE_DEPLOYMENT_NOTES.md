# Stored Procedure Deployment Notes

## Master Script

The file `99_Create_All_Procedures.sql` will create all stored procedures in the correct order.

**Usage:**
1. In SQL Server Management Studio, enable SQLCMD mode (Query > SQLCMD Mode)
2. Set the current directory to `jit_framework/database/procedures/`
3. Execute `99_Create_All_Procedures.sql`

**Alternative (without SQLCMD):**
Run each procedure script individually in the order listed in `99_Create_All_Procedures.sql`

## Procedure Dependencies

Procedures must be created in this order:

1. **Identity Management** (no dependencies on other procedures)
   - sp_User_ResolveCurrentUser
   - sp_User_GetByLogin
   - sp_User_SyncFromAD
   - sp_User_Eligibility_Check

2. **Role Management** (depends on identity procedures)
   - sp_Role_ListRequestable

3. **Request Workflow** (depends on identity and role procedures)
   - sp_Request_Create
   - sp_Request_ListForUser
   - sp_Request_ListPendingForApprover
   - sp_Request_Cancel
   - sp_Request_Approve
   - sp_Request_Deny

4. **Grant Management** (depends on request procedures)
   - sp_Grant_Issue
   - sp_Grant_Expire
   - sp_Grant_ListActiveForUser

## Schema Fixes Applied

**Issue:** `sp_Grant_Expire` was trying to update `UpdatedUtc` column in `Grants` table, but this column doesn't exist.

**Fix:** Removed the `UpdatedUtc = GETUTCDATE()` line from the UPDATE statement in `sp_Grant_Expire.sql`

**Verification:** All other column references in procedures have been verified against the schema definitions.

## Table Column Reference

For reference, the `Grants` table has these columns:
- GrantId (PK)
- RequestId (FK)
- UserId (FK)
- RoleId (FK)
- ValidFromUtc
- ValidToUtc
- RevokedUtc
- RevokeReason
- IssuedByUserId (FK)
- Status

Note: `Grants` table does NOT have `UpdatedUtc` column (unlike `Requests` and `Users` tables which do).

