# Just-In-Time Access Framework - Updated Implementation Plan

**Last Updated**: Current version reflecting all implemented changes

## Overview

This document outlines the complete implementation plan for a comprehensive JIT (Just-In-Time) access framework for SQL Server database access control, featuring a Flask web frontend with dark mode design.

## Architecture Summary

### Technology Stack
- **Backend Database**: SQL Server (T-SQL stored procedures, tables, SQL Agent jobs)
- **Frontend**: Python Flask web application
- **Styling**: HTML5, CSS3 with minimalist dark mode design
- **Database Connection**: SQL Server Authentication with service account
- **User Identification**: Windows username (from environment variables or request headers)

### Core Principles
1. **Role-Based Access Control (RBAC)**: Access is granted through database roles
2. **Just-In-Time**: Temporary role membership with automatic expiration
3. **Multi-Role Requests**: Users can request multiple roles in a single request (all-or-nothing approval)
4. **Audit Trail**: Complete auditability of all access grants and changes
5. **Self-Service with Conditional Approval**: 
   - Pre-approved roles (`RequiresApproval = 0`)
   - Seniority-based auto-approval (`SeniorityLevel >= AutoApproveMinSeniority`)
   - Manual approval for sensitive roles
6. **Multi-Scope Eligibility**: Eligibility rules support user, department, division, team, or global scopes
7. **Division + Seniority Approval Model**: Approvers can approve requests from colleagues in their division if they have sufficient seniority

---

## Phase 1: Database Schema Design

### 1.1 Identity Management Schema (`jit` schema)

#### Core Tables:

**1. `jit.Users`** - User identity and AD enrichment
- UserId (PK, int identity)
- LoginName (nvarchar(255), UNIQUE, indexed) - Windows login name
- GivenName, Surname, DisplayName (nvarchar(255))
- Email (nvarchar(255), nullable)
- Division (nvarchar(255), nullable, indexed) - Organizational division
- Department (nvarchar(255), nullable)
- JobTitle (nvarchar(255), nullable)
- **SeniorityLevel** (int, nullable, indexed) - Numeric seniority (1=most junior, higher=more senior). Used for auto-approval bypass
- ManagerLoginName (nvarchar(255), nullable)
- **IsAdmin** (bit, default 0, indexed) - Admin flag
- IsActive (bit, default 1, indexed)
- LastAdSyncUtc (datetime2)
- CreatedUtc, UpdatedUtc (datetime2)
- CreatedBy, UpdatedBy (nvarchar(255))

**Indexes:**
- `IX_Users_LoginName` (unique, nonclustered)
- `IX_Users_IsActive` (filtered: WHERE IsActive = 1)
- `IX_Users_IsAdmin` (filtered: WHERE IsAdmin = 1)
- `IX_Users_Division_SeniorityLevel` (composite: Division, SeniorityLevel, filtered: WHERE Division IS NOT NULL AND SeniorityLevel IS NOT NULL)

**2. `jit.Roles`** - Business role catalog (requestable roles)
- RoleId (PK, int identity)
- RoleName (nvarchar(255), UNIQUE, indexed)
- Description (nvarchar(max))
- MaxDurationMinutes (int) - Maximum grant duration
- RequiresTicket (bit, default 0)
- TicketRegex (nvarchar(255), nullable) - Validation pattern
- RequiresJustification (bit, default 1)
- **RequiresApproval** (bit, default 1) - If 0, role is pre-approved (auto-granted if eligible)
- **AutoApproveMinSeniority** (int, nullable, indexed) - Minimum seniority level for auto-approval bypass
- IsEnabled (bit, default 1, indexed)
- CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy

**Indexes:**
- `IX_Roles_RoleName` (unique, nonclustered)
- `IX_Roles_IsEnabled` (filtered: WHERE IsEnabled = 1)
- `IX_Roles_RequiresApproval_AutoApproveMinSeniority` (composite: RequiresApproval, AutoApproveMinSeniority, filtered: WHERE AutoApproveMinSeniority IS NOT NULL)

**3. `jit.DB_Roles`** - Database role metadata
- DbRoleId (PK, int identity)
- DbRoleName (nvarchar(255), UNIQUE) - Must match actual DB role
- RoleType (nvarchar(50)) - e.g., 'data_reader', 'data_writer', 'ddm_unmask', 'mask_reader'
- Description (nvarchar(max))
- IsJitManaged (bit, default 1) - Whitelist flag
- HasUnmask (bit, default 0) - DDM UNMASK permission
- CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy

**4. `jit.Role_To_DB_Roles`** - Business role to DB role mapping
- RoleId (FK → jit.Roles)
- DbRoleId (FK → jit.DB_Roles)
- IsRequired (bit, default 1) - Required vs optional component
- PK: (RoleId, DbRoleId)

**5. `jit.Teams`** - Team metadata table
- TeamId (PK, int identity)
- TeamName (nvarchar(255), UNIQUE)
- Description (nvarchar(max), nullable)
- Division (nvarchar(255), nullable) - Optional division association
- Department (nvarchar(255), nullable) - Optional department association
- IsActive (bit, default 1)
- CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy

**6. `jit.User_Teams`** - User-to-Team membership (many-to-many)
- UserId (FK → jit.Users)
- TeamId (FK → jit.Teams)
- IsActive (bit, default 1)
- AssignedUtc (datetime2) - When user was added to team
- RemovedUtc (datetime2, nullable) - When user was removed (historical)
- PK: (UserId, TeamId)
- Index: (TeamId, IsActive)

**7. `jit.Role_Eligibility_Rules`** - Multi-scope eligibility rules
- EligibilityRuleId (PK, int identity)
- RoleId (FK → jit.Roles)
- ScopeType (nvarchar(50)) - 'User', 'Department', 'Division', 'Team', 'All'
- ScopeValue (nvarchar(255), nullable) - UserId (if User), Department name, Division name, TeamId, or NULL for 'All'
- CanRequest (bit, default 1) - True = eligible, False = explicitly denied
- ValidFromUtc, ValidToUtc (datetime2, nullable) - Time-bound eligibility
- Priority (int) - Higher priority rules override lower (for conflict resolution)
- CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy
- Index: (RoleId, ScopeType, ScopeValue)

**8. `jit.User_To_Role_Eligibility`** - Explicit per-user overrides (takes highest priority)
- UserId (FK → jit.Users)
- RoleId (FK → jit.Roles)
- CanRequest (bit) - True = allow (overrides rules), False = deny (overrides rules)
- ValidFromUtc, ValidToUtc (datetime2, nullable) - Time-bound eligibility
- Priority (int) - Higher than Role_Eligibility_Rules (user-specific takes precedence)
- PK: (UserId, RoleId)

**Note**: `jit.Role_Approvers` table has been **REMOVED**. Approval logic is now based on Division + Seniority matching.

### 1.2 Workflow Schema

**9. `jit.Requests`** - Access requests (NO RoleId - uses Request_Roles junction table)
- RequestId (PK, bigint identity)
- UserId (FK → jit.Users, indexed)
- RequestedDurationMinutes (int) - Minimum of all selected roles' MaxDurationMinutes
- Justification (nvarchar(max))
- TicketRef (nvarchar(255), nullable) - Required if ANY selected role requires ticket
- Status (nvarchar(50), indexed) - 'Pending', 'Approved', 'AutoApproved', 'Denied', 'Cancelled', 'Expired', 'Revoked'
- UserDeptSnapshot (nvarchar(255)) - Audit trail preservation
- UserTitleSnapshot (nvarchar(255))
- CreatedUtc, UpdatedUtc
- CreatedBy (nvarchar(255))

**Indexes:**
- `IX_Requests_UserId` (nonclustered)
- `IX_Requests_Status` (filtered: WHERE Status IN ('Pending', 'AutoApproved'))

**10. `jit.Request_Roles`** - **NEW**: Junction table for many-to-many relationship between Requests and Roles
- RequestId (FK → jit.Requests, indexed)
- RoleId (FK → jit.Roles, indexed)
- CreatedUtc (datetime2) - Default: GETUTCDATE()
- PK: (RequestId, RoleId)
- Foreign Keys: CASCADE DELETE on Requests, CASCADE DELETE on Roles

**Indexes:**
- `IX_Request_Roles_RequestId` (nonclustered)
- `IX_Request_Roles_RoleId` (nonclustered)

**11. `jit.Approvals`** - Approval decisions
- ApprovalId (PK, bigint identity)
- RequestId (FK → jit.Requests)
- ApproverUserId (FK → jit.Users, nullable)
- ApproverLoginName (nvarchar(255)) - For audit even if not in jit.Users
- Decision (nvarchar(50)) - 'Approved', 'Denied'
- DecisionComment (nvarchar(max), nullable) - Combined comment/denial reason
- DecisionUtc (datetime2)

**12. `jit.Grants`** - Active and historical access grants (one grant per role)
- GrantId (PK, bigint identity)
- RequestId (FK → jit.Requests, nullable) - Nullable for admin grants
- UserId (FK → jit.Users, indexed)
- RoleId (FK → jit.Roles, indexed)
- ValidFromUtc, ValidToUtc (datetime2)
- RevokedUtc (datetime2, nullable)
- RevokeReason (nvarchar(max), nullable)
- IssuedByUserId (FK → jit.Users, nullable)
- Status (nvarchar(50), indexed) - 'Active', 'Expired', 'Revoked'
- Indexes: (UserId, RoleId, Status, ValidToUtc)

**13. `jit.Grant_DBRole_Assignments`** - Actual DB role membership operations
- GrantId (FK → jit.Grants)
- DbRoleId (FK → jit.DB_Roles)
- AddAttemptUtc (datetime2, nullable)
- AddSucceeded (bit, nullable)
- AddError (nvarchar(max), nullable)
- DropAttemptUtc (datetime2, nullable)
- DropSucceeded (bit, nullable)
- DropError (nvarchar(max), nullable)
- PK: (GrantId, DbRoleId)

### 1.3 Audit Schema

**14. `jit.AuditLog`** - Comprehensive audit trail
- AuditId (PK, bigint identity)
- EventUtc (datetime2, indexed)
- EventType (nvarchar(100), indexed) - 'RequestCreated', 'Approved', 'Denied', 'GrantIssued', 'RoleAdded', 'RoleDropped', 'ExpiredJobRun', etc.
- ActorUserId (FK → jit.Users, nullable) - Nullable for system jobs
- ActorLoginName (nvarchar(255), indexed) - Always populated
- TargetUserId (FK → jit.Users, nullable)
- RequestId (FK → jit.Requests, nullable)
- GrantId (FK → jit.Grants, nullable)
- DetailsJson (nvarchar(max)) - Flexible JSON storage for event details
- Index: (EventUtc, EventType, ActorLoginName)

---

## Phase 2: Core Stored Procedures

### 2.1 Identity Management Procedures

**`jit.sp_User_ResolveCurrentUser`**
- Resolves Windows username to UserId
- **No auto-creation** - returns NULL if user not found
- Returns UserId and user metadata (including IsAdmin, SeniorityLevel, Division)

**`jit.sp_User_SyncFromAD`**
- PowerShell/AD sync integration point
- Upsert users from AD data
- Optionally sync SeniorityLevel from AD attribute or derive from JobTitle
- Marks users as inactive if missing from AD
- Logs sync activity

**`jit.sp_User_GetByLogin`**
- Fast lookup by login name
- Used throughout system for user resolution
- Returns user details including IsAdmin, SeniorityLevel, Division

**`jit.sp_User_Eligibility_Check`**
- Core eligibility resolution logic
- Checks if user can request a specific role
- Resolution order (highest to lowest priority):
  1. User_To_Role_Eligibility explicit user overrides
  2. Role_Eligibility_Rules with ScopeType='User' matching UserId
  3. Role_Eligibility_Rules with ScopeType='Team' where user is active member
  4. Role_Eligibility_Rules with ScopeType='Department' matching user's department
  5. Role_Eligibility_Rules with ScopeType='Division' matching user's division
  6. Role_Eligibility_Rules with ScopeType='All'
- Returns eligibility result (can request: yes/no/denied)

### 2.2 Role Management Procedures

**`jit.sp_Role_ListRequestable`**
- Lists roles a user can request
- Filters by eligibility (uses `sp_User_Eligibility_Check`)
- Excludes roles user already has active grants for
- Excludes roles user has pending requests for
- Only shows enabled roles

### 2.3 Request Workflow Procedures

**`jit.sp_Request_Create`** - **UPDATED**: Multi-role support
- **New Parameter**: `@RoleIds` (nvarchar(MAX), comma-separated list of role IDs)
- **Validation Phase** (fail fast if any issue):
  - Validates all role IDs exist and are enabled
  - Checks eligibility for ALL selected roles (calls `sp_User_Eligibility_Check` for each)
  - Verifies user doesn't have active grants for ANY selected role
  - Verifies user doesn't have pending requests for ANY selected role
  - Gets role metadata: `MIN(MaxDurationMinutes)`, `MAX(RequiresTicket)`, `MAX(RequiresJustification)`
  - Validates `@RequestedDurationMinutes` doesn't exceed minimum max duration
- **Request Creation**:
  - Creates single `Requests` record (no RoleId column)
  - Inserts into `Request_Roles` junction table for each role
- **Auto-Approval Logic** (3-tier):
  1. **Pre-approved**: If ALL roles have `RequiresApproval = 0` → Status = 'AutoApproved'
  2. **Seniority bypass**: If user's `SeniorityLevel >= ALL roles' AutoApproveMinSeniority` → Status = 'AutoApproved'
  3. **Manual approval**: Otherwise → Status = 'Pending'
- **Grant Issuance**:
  - For auto-approved requests: Calls `sp_Grant_Issue` for EACH role in the request
  - Creates one grant per role

**`jit.sp_Request_GetRoles`** - **NEW**: Helper procedure
- Returns all roles associated with a given request
- Joins `Request_Roles` with `Roles` table
- Used by Flask app to display role details

**`jit.sp_Request_ListForUser`**
- Returns all requests (history) for a user
- Joins with `Request_Roles` and `Roles` to aggregate role names
- Uses `STRING_AGG` for multi-role display
- Returns `RoleNames` as comma-separated string

**`jit.sp_Request_ListPendingForApprover`**
- Returns pending requests where approver can approve ALL roles
- Filters based on Division + Seniority matching:
  - Approver and requester must be in same division
  - Approver's seniority must be >= all roles' `AutoApproveMinSeniority`
  - Requester's seniority must be < approver's seniority
  - OR approver is admin (can approve any request)
- Joins with `Request_Roles` and `Roles`
- Uses `STRING_AGG` for `RoleNames`
- Only shows requests where approver can approve ALL roles (all-or-nothing)

**`jit.sp_Approver_CanApproveRequest`** - **NEW**: Centralized approval permission check
- Checks if an approver can approve a specific request
- Validates that approver can approve ALL roles in the request
- Logic:
  1. Admin override: If approver is admin → return 1
  2. Division + Seniority: Check all roles:
     - Approver and requester in same division
     - Approver's seniority >= each role's `AutoApproveMinSeniority`
     - Requester's seniority < approver's seniority
     - If ANY role fails check → return 0
     - If ALL roles pass → return 1
- Used by `sp_Request_ListPendingForApprover` and Flask app

**`jit.sp_Request_Approve`**
- Processes approval decision
- Validates approver can approve ALL roles (calls `sp_Approver_CanApproveRequest`)
- Iterates through all roles in `Request_Roles`
- Calls `sp_Grant_Issue` for EACH role
- Creates one grant per role
- Records approval in `Approvals` table

**`jit.sp_Request_Deny`**
- Processes denial decision
- Updates request status to 'Denied'
- Records denial in `Approvals` table with comment

**`jit.sp_Request_Cancel`**
- Allows users to cancel pending requests
- Updates request status to 'Cancelled'
- Logs audit event

### 2.4 Grant Management Procedures

**`jit.sp_Grant_Issue`**
- Creates grant record for a single role
- Adds user to all associated DB roles (via `Role_To_DB_Roles`)
- Tracks DB role assignment operations in `Grant_DBRole_Assignments`
- Sets grant expiration (`ValidToUtc`)
- Logs audit events

**`jit.sp_Grant_Expire`**
- Processes expired grants
- Removes users from DB roles
- Updates grant status to 'Expired'
- Logs audit events

**`jit.sp_Grant_ListActiveForUser`**
- Lists active grants for a user
- Shows role details and expiration times
- Filters by `Status = 'Active'` and `ValidToUtc > GETUTCDATE()`

---

## Phase 3: Approval Model

### Approval Logic (Division + Seniority Based)

**Approvers can approve requests where:**
1. **Admin Override**: User has `IsAdmin = 1` → Can approve ANY request
2. **Division + Seniority Match**: 
   - Approver and requester are in same division (`approver.Division = requester.Division`)
   - Approver's `SeniorityLevel >= ALL roles' AutoApproveMinSeniority`
   - Requester's `SeniorityLevel < approver.SeniorityLevel`
   - All roles in request must pass these checks (all-or-nothing)

**Note**: `Role_Approvers` table has been removed. Approval is automatic based on division and seniority matching.

---

## Phase 4: Flask Application

### 4.1 Architecture

**Database Connection**:
- Uses SQL Server Authentication with service account
- Connection string from environment variables (`.env` file)
- Service account has EXECUTE on schema, SELECT/INSERT/UPDATE/DELETE on tables

**User Identification**:
- Uses Windows username from environment variables (development) or request headers (production)
- No auto-user creation - users must exist in `jit.Users` table

**Authentication Utilities** (`utils/auth.py`):
- `get_current_user()`: Resolves Windows username to user record
- `is_approver(user_id)`: Checks if user can approve (admin OR has division + seniority)
- `is_admin(user_id)`: Checks `IsAdmin` flag
- Decorators: `@login_required`, `@approver_required`, `@admin_required`

### 4.2 Routes

**User Routes**:
- `/user/dashboard` - View active grants
- `/user/request` - Request access (multi-role selection)
- `/user/history` - View request history
- `/user/cancel/<id>` - Cancel pending request

**Approver Routes**:
- `/approver/dashboard` - View pending requests (only requests where approver can approve ALL roles)
- `/approver/request/<id>` - Review request details (shows all roles)
- `/approver/approve/<id>` - Approve request
- `/approver/deny/<id>` - Deny request

**Admin Routes**:
- `/admin/dashboard` - Admin dashboard
- Additional admin management routes (roles, teams, eligibility, users, reports)

### 4.3 Frontend

**Request Form** (`templates/user/request.html`):
- Checkbox list for role selection (replaces single dropdown)
- Dynamic calculation of minimum duration (JavaScript)
- Dynamic ticket requirement (required if ANY role requires it)
- Shows selected role count
- Real-time validation

**Approval Page** (`templates/approver/approve.html`):
- Displays all roles in the request
- Single comment field (used for both approval and denial)
- Shows requester details (name, department, division, seniority)
- Shows role details (name, description, max duration, ticket requirement)

---

## Phase 5: Deployment

### 5.1 Database Deployment

**Master Script**: `database/01_Deploy_Everything.sql`
1. Creates schema (`jit`)
2. Creates all tables (in dependency order)
3. Creates all stored procedures (in dependency order)
4. Optionally inserts test data (commented out by default)

**Cleanup Script**: `database/02_Cleanup_Everything.sql`
- Drops all stored procedures
- Drops all tables (in reverse dependency order)
- Drops schema (optional)
- **WARNING**: Deletes all data!

### 5.2 Service Account Setup

1. Create SQL Server login
2. Create database user
3. Grant permissions:
   - `GRANT EXECUTE ON SCHEMA::jit TO [JIT_ServiceAccount]`
   - `GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::jit TO [JIT_ServiceAccount]`

### 5.3 Flask Application Deployment

1. Install Python dependencies: `pip install -r requirements.txt`
2. Create `.env` file with database connection settings
3. Run application: `python app.py`
4. For production: Use WSGI server (Gunicorn, uWSGI) or IIS with FastCGI

---

## Implementation Status

✅ **Completed**:
- Database schema (all 14 tables + Request_Roles)
- All stored procedures (identity, roles, requests, grants, approval)
- Multi-role request support
- Division + Seniority approval model
- Flask application structure
- User, approver, and admin routes
- Multi-role request form
- Approval page with role details
- Service account authentication
- Comprehensive indexes

⚠️ **Partially Complete**:
- Some admin management routes (templates missing)
- SQL Agent jobs (expiry job script exists, needs scheduling)
- AD sync integration (procedure exists, job needs setup)

📋 **Future Enhancements**:
- Reporting procedures
- Grant reconciliation procedure
- IIS/Windows Auth integration documentation
- Comprehensive error handling improvements
- Input validation enhancements
- Audit report views

---

## Key Design Decisions

1. **Multi-Role Requests**: All-or-nothing approval (approver must be able to approve ALL roles)
2. **Approval Model**: Division + Seniority based (no `Role_Approvers` table needed)
3. **Auto-Approval**: 3-tier logic (pre-approved, seniority bypass, manual approval)
4. **Grants**: One grant per role (independent expiration tracking)
5. **User Creation**: No auto-creation (users must exist in database)
6. **Database Connection**: Service account (SQL Server Authentication)
7. **User Identification**: Windows username (separate from database connection)

---

## Notes

- The framework uses SQL Server Authentication with a service account for database connections
- User identification uses Windows username (from environment variables or request headers)
- Users must be created manually or via AD sync - no auto-creation
- SQL Agent jobs must be configured for automatic expiration
- Review and configure security permissions for the `jit` schema and service account
- Store service account credentials securely (use environment variables, not hardcoded values)

