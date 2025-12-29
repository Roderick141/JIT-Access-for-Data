# Just-In-Time Access Framework - Implementation Plan

## Overview
This document outlines the implementation plan for a comprehensive JIT (Just-In-Time) access framework for SQL Server database access control, featuring a Flask web frontend with dark mode design.

## Architecture Summary

### Technology Stack
- **Backend Database**: SQL Server (T-SQL stored procedures, tables, SQL Agent jobs)
- **Frontend**: Python Flask web application
- **Styling**: HTML5, CSS3 with minimalist dark mode design
- **Authentication**: Windows Authentication (integrated with SQL Server)

### Core Principles
1. **Role-Based Access Control (RBAC)**: Access is granted through database roles
2. **Just-In-Time**: Temporary role membership with automatic expiration
3. **Audit Trail**: Complete auditability of all access grants and changes
4. **Defense in Depth**: Multiple layers of security controls
5. **Self-Service with Conditional Approval**: Users can request access; roles can be pre-approved (auto-granted), seniority-based auto-approved, or require manual approval
6. **Multi-Scope Eligibility**: Eligibility rules support user, department, division, team, or global scopes
7. **Seniority-Based Access Control**: Senior users can bypass approval for appropriate roles while maintaining controls for junior staff

---

## Phase 1: Database Schema Design

### 1.1 Identity Management Schema (`jit` schema)

#### Tables:

**1. `jit.Users`** - User identity and AD enrichment
- UserId (PK, int identity)
- LoginName (nvarchar(255), UNIQUE) - Canonical login from ORIGINAL_LOGIN()
- GivenName, Surname, DisplayName (nvarchar(255))
- Email (nvarchar(255), nullable)
- Division (nvarchar(255), nullable) - Organizational division
- Department (nvarchar(255), nullable)
- JobTitle (nvarchar(255), nullable)
- SeniorityLevel (int, nullable) - **NEW**: Numeric seniority (1=most junior, higher=more senior). Used for auto-approval bypass
- ManagerLoginName (nvarchar(255), nullable) - For approval routing
- IsActive (bit, default 1)
- LastAdSyncUtc (datetime2)
- CreatedUtc, UpdatedUtc (datetime2)
- CreatedBy, UpdatedBy (nvarchar(255))

**2. `jit.Roles`** - Business role catalog (requestable roles)
- RoleId (PK, int identity)
- RoleName (nvarchar(255), UNIQUE)
- Description (nvarchar(max))
- MaxDurationMinutes (int) - Maximum grant duration
- RequiresTicket (bit, default 0)
- TicketRegex (nvarchar(255), nullable) - Validation pattern
- RequiresJustification (bit, default 1)
- RequiresApproval (bit, default 1) - If 0, role is pre-approved (auto-granted if eligible)
- AutoApproveMinSeniority (int, nullable) - **NEW**: Minimum seniority level for auto-approval bypass. If user.SeniorityLevel >= this value, auto-approve even if RequiresApproval=1
- IsEnabled (bit, default 1)
- CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy

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
- CreatedUtc, UpdatedUtc (datetime2)
- CreatedBy, UpdatedBy (nvarchar(255))

**6. `jit.User_Teams`** - User-to-Team membership (many-to-many)
- UserId (FK → jit.Users)
- TeamId (FK → jit.Teams)
- IsActive (bit, default 1)
- AssignedUtc (datetime2) - When user was added to team
- RemovedUtc (datetime2, nullable) - When user was removed (historical)
- PK: (UserId, TeamId)
- Index: (TeamId, IsActive)

**7. `jit.Role_Eligibility_Rules`** - **ENHANCED**: Multi-scope eligibility rules
- EligibilityRuleId (PK, int identity)
- RoleId (FK → jit.Roles)
- ScopeType (nvarchar(50)) - 'User', 'Department', 'Division', 'Team', 'All'
- ScopeValue (nvarchar(255), nullable) - UserId (if User), Department name, Division name, TeamId, or NULL for 'All'
- CanRequest (bit, default 1) - True = eligible, False = explicitly denied
- ValidFromUtc, ValidToUtc (datetime2, nullable) - Time-bound eligibility
- Priority (int) - Higher priority rules override lower (for conflict resolution)
- CreatedUtc, UpdatedUtc (datetime2)
- CreatedBy, UpdatedBy (nvarchar(255))
- Index: (RoleId, ScopeType, ScopeValue, IsActive) where IsActive computed from ValidFromUtc/ValidToUtc

**8. `jit.User_To_Role_Eligibility`** - Explicit per-user overrides (still useful for exceptions)
- UserId (FK → jit.Users)
- RoleId (FK → jit.Roles)
- CanRequest (bit) - True = allow (overrides rules), False = deny (overrides rules)
- ValidFromUtc, ValidToUtc (datetime2, nullable) - Time-bound eligibility
- Priority (int) - Higher than Role_Eligibility_Rules (user-specific takes precedence)
- PK: (UserId, RoleId)
- **Note**: This table is now for explicit user-level overrides that take precedence over scope-based rules

**9. `jit.Role_Approvers`** - Approval routing configuration (only used when RequiresApproval = 1)
- RoleId (FK → jit.Roles)
- ApproverUserId (FK → jit.Users, nullable) - Specific user
- ApproverLoginName (nvarchar(255), nullable) - For users not yet in jit.Users
- ApproverType (nvarchar(50)) - 'User', 'Manager', 'Department'
- Priority (int) - Approval order
- PK: (RoleId, ApproverUserId, ApproverType, Priority)

### 1.2 Workflow Schema

**10. `jit.Requests`** - Access requests
- RequestId (PK, bigint identity)
- UserId (FK → jit.Users)
- RoleId (FK → jit.Roles)
- RequestedDurationMinutes (int)
- Justification (nvarchar(max))
- TicketRef (nvarchar(255), nullable)
- Status (nvarchar(50)) - 'Pending', 'Approved', 'AutoApproved', 'Denied', 'Cancelled', 'Expired', 'Revoked'
- **NEW**: 'AutoApproved' status for pre-approved roles (RequiresApproval=0)
- UserDeptSnapshot (nvarchar(255)) - Audit trail preservation
- UserTitleSnapshot (nvarchar(255))
- CreatedUtc, UpdatedUtc
- CreatedBy (nvarchar(255))

**11. `jit.Approvals`** - Approval decisions
- ApprovalId (PK, bigint identity)
- RequestId (FK → jit.Requests)
- ApproverUserId (FK → jit.Users, nullable)
- ApproverLoginName (nvarchar(255)) - For audit even if not in jit.Users
- Decision (nvarchar(50)) - 'Approved', 'Denied'
- DecisionComment (nvarchar(max), nullable)
- DecisionUtc (datetime2)

**12. `jit.Grants`** - Active and historical access grants
- GrantId (PK, bigint identity)
- RequestId (FK → jit.Requests, nullable) - Nullable for admin grants
- UserId (FK → jit.Users)
- RoleId (FK → jit.Roles)
- ValidFromUtc, ValidToUtc (datetime2)
- RevokedUtc (datetime2, nullable)
- RevokeReason (nvarchar(max), nullable)
- IssuedByUserId (FK → jit.Users, nullable)
- Status (nvarchar(50)) - 'Active', 'Expired', 'Revoked'
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
- EventUtc (datetime2)
- EventType (nvarchar(100)) - 'RequestCreated', 'Approved', 'Denied', 'GrantIssued', 'RoleAdded', 'RoleDropped', 'ExpiredJobRun', 'AdSync', 'UserSync', etc.
- ActorUserId (FK → jit.Users, nullable) - Nullable for system jobs
- ActorLoginName (nvarchar(255)) - Always populated
- TargetUserId (FK → jit.Users, nullable)
- RequestId (FK → jit.Requests, nullable)
- GrantId (FK → jit.Grants, nullable)
- DetailsJson (nvarchar(max)) - Flexible JSON storage for event details
- Index: (EventUtc, EventType, ActorLoginName)

---

## Phase 2: Core Stored Procedures

### 2.1 Identity Management Procedures

**`jit.sp_User_ResolveCurrentUser`**
- Resolves ORIGINAL_LOGIN() to UserId
- Creates user record if not exists
- Returns UserId and user metadata

**`jit.sp_User_SyncFromAD`**
- PowerShell/AD sync integration point
- Upsert users from AD data
- **NEW**: Optionally sync SeniorityLevel from AD attribute or derive from JobTitle
- Marks users as inactive if missing from AD
- Logs sync activity

**`jit.sp_User_GetByLogin`**
- Fast lookup by login name
- Used throughout system for user resolution

**`jit.sp_User_Eligibility_Check`**
- **NEW**: Core eligibility resolution logic
- Checks if user can request a specific role
- Resolution order (highest to lowest priority):
  1. User_To_Role_Eligibility explicit user overrides
  2. Role_Eligibility_Rules with ScopeType='User' matching UserId
  3. Role_Eligibility_Rules with ScopeType='Team' where user is member
  4. Role_Eligibility_Rules with ScopeType='Department' matching user's department
  5. Role_Eligibility_Rules with ScopeType='Division' matching user's division
  6. Role_Eligibility_Rules with ScopeType='All'
- Returns eligibility result (can request: yes/no/denied)

### 2.2 Team Management Procedures

**`jit.sp_Team_Create`**
- Creates new team record
- Validates team name uniqueness
- Logs audit event

**`jit.sp_Team_Update`**
- Updates team metadata
- Logs audit event

**`jit.sp_Team_AddMember`**
- Adds user to team
- Updates User_Teams table
- Logs audit event

**`jit.sp_Team_RemoveMember`**
- Removes user from team (soft delete - sets IsActive=0)
- Updates RemovedUtc timestamp
- Logs audit event

**`jit.sp_Team_ListMembers`**
- Returns all active members of a team
- Used by admin interface

**`jit.sp_Team_ListForUser`**
- Returns all teams a user belongs to
- Used for eligibility checks

### 2.3 Eligibility Management Procedures

**`jit.sp_EligibilityRule_Create`**
- Creates new eligibility rule
- Validates scope type and value
- Supports: User, Department, Division, Team, All
- Logs audit event

**`jit.sp_EligibilityRule_Update`**
- Updates eligibility rule
- Validates scope changes
- Logs audit event

**`jit.sp_EligibilityRule_Delete`**
- Deletes eligibility rule (soft delete if needed, or hard delete)
- Logs audit event

**`jit.sp_EligibilityRule_ListForRole`**
- Returns all eligibility rules for a role
- Used by admin interface for rule management

### 2.4 Role Management Procedures

**`jit.sp_Role_ListRequestable`**
- Returns roles user can request (based on eligibility rules + enabled)
- Checks eligibility via:
  1. User_To_Role_Eligibility (explicit user overrides - highest priority)
  2. Role_Eligibility_Rules matching user's Division/Department/Teams
  3. Role_Eligibility_Rules with ScopeType='All'
- Used by frontend for role selection

**`jit.sp_Role_GetDetails`**
- Returns full role details including DB role mappings
- Includes approval requirements

**`jit.sp_DBRole_ValidateMembership`**
- Validates actual DB role membership matches jit.Grants
- Used by reconciliation job

### 2.5 Request Workflow Procedures

**`jit.sp_Request_Create`**
- Creates new access request
- Validates eligibility (using same logic as sp_Role_ListRequestable)
- **Auto-approval logic** (in priority order):
  1. If role.RequiresApproval = 0: Auto-approve (pre-approved role)
  2. If role.RequiresApproval = 1 AND role.AutoApproveMinSeniority IS NOT NULL:
     - If user.SeniorityLevel >= role.AutoApproveMinSeniority: Auto-approve (seniority bypass)
     - Else: Requires approval (status = 'Pending')
  3. If role.RequiresApproval = 1 AND role.AutoApproveMinSeniority IS NULL: Requires approval (status = 'Pending')
- If auto-approved, calls sp_Grant_Issue immediately, sets status = 'AutoApproved'
- Logs audit event (including auto-approval reason: 'PreApprovedRole' or 'SeniorityBypass')

**`jit.sp_Request_Approve`**
- Processes approval decision
- Creates grant if approved
- Calls sp_Grant_Issue to add role memberships
- Logs audit events

**`jit.sp_Request_Deny`**
- Processes denial decision
- Updates request status
- Logs audit event

**`jit.sp_Request_Cancel`**
- Allows requester to cancel pending requests
- Updates status

**`jit.sp_Request_ListPendingForApprover`**
- Returns pending requests for a specific approver
- Used by approver portal

**`jit.sp_Request_ListForUser`**
- Returns all requests (history) for a user
- Used by user portal

### 2.6 Grant Management Procedures

**`jit.sp_Grant_Issue`**
- Creates grant record
- Adds user to DB roles (via ALTER ROLE ... ADD MEMBER)
- Records operations in Grant_DBRole_Assignments
- Handles errors gracefully
- Logs audit events

**`jit.sp_Grant_Revoke`**
- Revokes active grant
- Removes user from DB roles (via ALTER ROLE ... DROP MEMBER)
- Updates grant status
- Logs audit events

**`jit.sp_Grant_Expire`**
- Called by expiry job
- Processes expired grants
- Removes role memberships
- Updates grant status
- Logs audit events

**`jit.sp_Grant_ListActiveForUser`**
- Returns active grants for user
- Used by user portal

**`jit.sp_Grant_Reconcile`**
- Reconciliation job procedure
- Compares jit.Grants to actual role membership
- Reports/fixes drift

### 2.7 Reporting Procedures

**`jit.sp_Report_ActiveGrants`**
- Returns all active grants with details
- Optional filters: user, role, expiring soon

**`jit.sp_Report_UserAccess`**
- Returns all access for a user (active grants + roles)

**`jit.sp_Report_DriftDetection`**
- Finds discrepancies between catalog and actual DB state
- Unmanaged roles, missing roles, permission drift

**`jit.sp_Report_DirectGrants`**
- Finds direct grants to users (bypassing role model)
- Security audit report

---

## Phase 3: SQL Agent Jobs

### 3.1 Expiry Job (`jit.Job_ExpireGrants`)
- **Schedule**: Every 5-15 minutes
- **Procedure**: `jit.sp_Grant_Expire`
- **Actions**:
  - Find grants where ValidToUtc < GETUTCDATE() and Status = 'Active'
  - Call sp_Grant_Revoke for each
  - Log results

### 3.2 Reconciliation Job (`jit.Job_ReconcileMembership`)
- **Schedule**: Every hour
- **Procedure**: `jit.sp_Grant_Reconcile`
- **Actions**:
  - Compare jit.Grants to actual role membership
  - Report drift (alert or repair)
  - Log discrepancies

### 3.3 AD Sync Job (`jit.Job_SyncAD`)
- **Schedule**: Daily (or hourly if needed)
- **Procedure**: `jit.sp_User_SyncFromAD`
- **Actions**:
  - Import AD data (via staging table or PowerShell)
  - Update jit.Users
  - Mark inactive users
  - Optionally trigger revokes for inactive users
  - Log sync results

---

## Phase 4: Flask Frontend Application

### 4.1 Application Structure
```
flask_app/
├── app.py                 # Main Flask application
├── config.py              # Configuration (DB connection, etc.)
├── requirements.txt       # Python dependencies
├── static/
│   ├── css/
│   │   └── darkmode.css   # Dark mode styles
│   └── js/
│       └── main.js        # Client-side JavaScript
├── templates/
│   ├── base.html          # Base template
│   ├── login.html         # Login page (if needed)
│   ├── user/
│   │   ├── dashboard.html # User dashboard
│   │   ├── request.html   # Request access form
│   │   └── history.html   # Request history
│   ├── approver/
│   │   ├── dashboard.html # Approver dashboard
│   │   └── approve.html   # Approval detail page
│   └── admin/
│       ├── dashboard.html # Admin dashboard
│       ├── roles.html     # Role catalog management
│       ├── users.html     # User management
│       └── reports.html   # Audit reports
└── utils/
    ├── db.py              # Database connection utilities
    ├── auth.py            # Authentication helpers
    └── decorators.py      # Flask decorators (roles, etc.)
```

### 4.2 Flask Routes

**Request Flow Behavior (Auto-Approval Logic):**
1. **Pre-Approved Role** (`RequiresApproval = 0`): All eligible users auto-approved immediately
2. **Seniority-Based Auto-Approval** (`RequiresApproval = 1` AND `AutoApproveMinSeniority IS NOT NULL`):
   - If `user.SeniorityLevel >= role.AutoApproveMinSeniority`: Auto-approved (bypass approval)
   - Else: Status = 'Pending', requires approver action
3. **Manual Approval Required** (`RequiresApproval = 1` AND `AutoApproveMinSeniority IS NULL`): Always requires approval

**Note**: Auto-approved requests have status = 'AutoApproved' and grant is issued immediately

#### User Routes (`/user/*`)
- `GET /user/dashboard` - View active grants, expiry dates
- `GET /user/request` - Request form (select role, duration, justification)
- `POST /user/request` - Submit request
- `GET /user/history` - Request history
- `GET /user/cancel/<request_id>` - Cancel pending request

#### Approver Routes (`/approver/*`)
- `GET /approver/dashboard` - Pending approvals queue
- `GET /approver/request/<request_id>` - Review request details
- `POST /approver/approve/<request_id>` - Approve request
- `POST /approver/deny/<request_id>` - Deny request

#### Admin Routes (`/admin/*`)
- `GET /admin/dashboard` - Admin overview
- `GET /admin/roles` - Manage role catalog (includes RequiresApproval and AutoApproveMinSeniority)
- `POST /admin/roles` - Create/update role
- `GET /admin/teams` - Manage teams
- `POST /admin/teams` - Create/update team
- `GET /admin/eligibility` - Manage eligibility rules
- `POST /admin/eligibility` - Create/update eligibility rule
- `GET /admin/users` - User list (AD sync status, includes SeniorityLevel)
- `POST /admin/users/<user_id>/seniority` - **NEW**: Update user seniority level
- `GET /admin/reports` - Audit reports and drift detection
- `POST /admin/revoke/<grant_id>` - Manual revoke

### 4.3 Design System (Dark Mode)

**Color Palette:**
- Background: #0d1117 (GitHub dark)
- Surface: #161b22
- Primary: #238636 (green for success/active)
- Secondary: #1f6feb (blue for info)
- Danger: #da3633 (red for deny/revoke)
- Warning: #d29922 (yellow for pending)
- Text Primary: #c9d1d9
- Text Secondary: #8b949e
- Border: #30363d

**UI Principles:**
- Minimalist, clean interface
- Card-based layouts
- Subtle shadows and borders
- Clear typography hierarchy
- Smooth transitions
- Accessible contrast ratios

---

## Phase 5: Security & Hardening

### 5.1 SQL Server Security
- **Schema Permissions**: Only framework admins can modify jit schema objects
- **Stored Procedure Execution**: Regular users can only execute specific whitelisted procedures
- **DDL Triggers**: Log ALTER ROLE, GRANT, REVOKE, DENY operations
- **Role Whitelisting**: Only roles in jit.DB_Roles with IsJitManaged=1 can be managed

### 5.2 Monitoring & Alerts
- Direct grants to users (bypass detection)
- Manual role membership changes (DDL trigger alerts)
- Failed grant operations
- Reconciliation drift detection alerts
- AD sync failures

### 5.3 Guardrails
- No self-approval (requestor cannot approve own request)
- Max duration enforcement
- Ticket validation (if required)
- Eligibility validation before request creation
- Idempotent operations (safe to retry)

---

## Phase 6: Implementation Phases

### Phase 6.1: Database Foundation (Week 1)
1. Create jit schema
2. Create all tables with proper indexes (including new Teams, User_Teams, Role_Eligibility_Rules, SeniorityLevel, AutoApproveMinSeniority)
3. Create core stored procedures (user resolution, role listing, eligibility checking)
4. Create team management procedures
5. Create eligibility rule management procedures
6. Create basic AD sync procedure and staging table (includes SeniorityLevel sync)
7. Test database operations including seniority-based auto-approval logic

### Phase 6.2: Workflow Procedures (Week 1-2)
1. Request creation and management procedures
2. Approval workflow procedures
3. Grant issuance and revocation procedures
4. Audit logging procedures
5. Testing with sample data

### Phase 6.3: Automation Jobs (Week 2)
1. Expiry job setup
2. Reconciliation job setup
3. AD sync job setup (or PowerShell script)
4. Testing and scheduling

### Phase 6.4: Flask Frontend - Core (Week 2-3)
1. Flask app setup and configuration
2. Database connection utilities
3. Authentication/authorization helpers
4. Base templates and dark mode CSS
5. User dashboard and request form

### Phase 6.5: Flask Frontend - Workflows (Week 3)
1. Approver dashboard and approval workflow
2. Admin dashboard and role management
3. **NEW**: Team management interface
4. **NEW**: Eligibility rule management interface
5. Reports and audit views
6. UI polish and responsive design
7. **NEW**: Display auto-approved requests differently in UI

### Phase 6.6: Integration & Testing (Week 4)
1. End-to-end testing
2. Security review
3. Performance optimization
4. Documentation
5. Deployment preparation

---

## Phase 7: Configuration & Deployment

### 7.1 Configuration Files
- `config.py` - Flask app configuration (DB connection string, etc.)
- Database configuration stored in SQL Server (tables for settings)

### 7.2 Deployment Checklist
- [ ] SQL Server database and schema created
- [ ] All tables created with proper indexes
- [ ] All stored procedures created
- [ ] SQL Agent jobs configured and tested
- [ ] Flask application deployed (IIS, Azure App Service, or standalone)
- [ ] Windows Authentication configured for Flask
- [ ] AD sync process configured (PowerShell or SSIS)
- [ ] Initial role catalog populated
- [ ] Initial user sync completed
- [ ] Security permissions configured
- [ ] Monitoring and alerts configured
- [ ] Documentation completed

---

## Additional Considerations

### PowerShell AD Sync
Create a PowerShell script that:
1. Queries Active Directory for user attributes
2. Exports to staging table (jit.AD_Staging)
3. Calls jit.sp_User_SyncFromAD to merge

### Error Handling
- All procedures should use TRY-CATCH blocks
- Detailed error logging to jit.AuditLog
- Frontend should display user-friendly error messages

### Performance
- Index all foreign keys and commonly queried columns
- Use appropriate index types (clustered vs non-clustered)
- Consider partitioning for large audit tables
- Cache role catalog in application layer

### Documentation
- Database schema documentation
- API documentation (stored procedure parameters)
- User guide for frontend
- Admin guide for role management
- Troubleshooting guide

---

## Next Steps

1. **Review this plan** with stakeholders
2. **Create subfolder structure** for new implementation
3. **Begin Phase 6.1**: Database schema creation
4. **Iterative development** with testing at each phase
5. **Documentation** as we build

This plan provides a comprehensive roadmap for implementing the JIT access framework. The modular approach allows for incremental development and testing.
