# Changes Made to JIT Framework Plan

## Summary of Enhancements

This document outlines the changes made to the original plan based on user feedback.

**Latest Update**: Added seniority-based auto-approval feature (Section 3)

---

## 1. Pre-Approved Roles (Auto-Approval)

### Changes Made:

**A. `jit.Roles` Table Enhancement:**
- **Added**: `RequiresApproval` (bit, default 1)
  - If `RequiresApproval = 0`: Role is pre-approved, requests are auto-granted
  - If `RequiresApproval = 1`: Role requires manual approval (existing behavior)

**B. `jit.Requests` Table Enhancement:**
- **Modified**: `Status` field now includes 'AutoApproved' as a valid status
  - Status values: 'Pending', 'Approved', **'AutoApproved'**, 'Denied', 'Cancelled', 'Expired', 'Revoked'

**C. `jit.sp_Request_Create` Procedure Logic:**
- **NEW Logic**: After eligibility validation:
  - Checks `role.RequiresApproval` flag
  - If `RequiresApproval = 0`: 
    - Sets status to 'AutoApproved'
    - Automatically calls `sp_Grant_Issue` to create grant
    - Logs audit event with EventType='RequestCreated' and 'GrantIssued'
  - If `RequiresApproval = 1`: 
    - Sets status to 'Pending'
    - Routes to approvers (existing behavior)

**D. Frontend Impact:**
- User portal should display auto-approved requests with different styling/icon
- Approver dashboard filters out auto-approved requests (they never appear in pending queue)
- Admin reports can show auto-approved vs manually approved statistics

---

## 2. Multi-Scope Eligibility System

### Changes Made:

**A. New Table: `jit.Teams`**
- TeamId (PK, int identity)
- TeamName (nvarchar(255), UNIQUE)
- Description (nvarchar(max), nullable)
- Division (nvarchar(255), nullable) - Optional organizational association
- Department (nvarchar(255), nullable) - Optional organizational association
- IsActive (bit, default 1)
- CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy
- **Purpose**: Metadata table for managing teams that users can belong to

**B. New Table: `jit.User_Teams`**
- UserId (FK → jit.Users)
- TeamId (FK → jit.Teams)
- IsActive (bit, default 1)
- AssignedUtc (datetime2)
- RemovedUtc (datetime2, nullable) - For historical tracking
- PK: (UserId, TeamId)
- Index: (TeamId, IsActive)
- **Purpose**: Many-to-many relationship allowing users to belong to multiple teams

**C. Enhanced Table: `jit.Users`**
- **Added**: `Division` (nvarchar(255), nullable)
  - Organizational division from AD
  - Used for division-level eligibility rules

**D. Replaced Table: `jit.Role_Eligibility_Rules` (NEW)**
- **Replaces the old simple `User_To_Role_Eligibility` approach**
- EligibilityRuleId (PK, int identity)
- RoleId (FK → jit.Roles)
- ScopeType (nvarchar(50)) - 'User', 'Department', 'Division', 'Team', 'All'
- ScopeValue (nvarchar(255), nullable)
  - If ScopeType='User': UserId
  - If ScopeType='Department': Department name
  - If ScopeType='Division': Division name
  - If ScopeType='Team': TeamId
  - If ScopeType='All': NULL (applies to everyone)
- CanRequest (bit, default 1) - True = eligible, False = explicitly denied
- ValidFromUtc, ValidToUtc (datetime2, nullable)
- Priority (int) - For conflict resolution (higher = more important)
- CreatedUtc, UpdatedUtc, CreatedBy, UpdatedBy
- **Purpose**: Flexible eligibility rules supporting multiple organizational scopes

**E. Updated Table: `jit.User_To_Role_Eligibility` (Still exists, repurposed)**
- **Purpose Changed**: Now used for explicit per-user overrides
- Takes precedence over all scope-based rules (highest priority)
- Useful for:
  - Granting access to specific individuals outside normal eligibility
  - Explicitly denying access to specific individuals
  - Time-bound user-specific access

### Eligibility Resolution Logic:

The system now uses a priority-based eligibility resolution:

1. **Highest Priority**: `jit.User_To_Role_Eligibility` (explicit user overrides)
   - If user has explicit entry, use that (allow or deny)

2. **Priority Order for `jit.Role_Eligibility_Rules`** (if no explicit override):
   - User-specific rules (ScopeType='User' matching UserId)
   - Team rules (ScopeType='Team' where user is active team member)
   - Department rules (ScopeType='Department' matching user.Department)
   - Division rules (ScopeType='Division' matching user.Division)
   - All rules (ScopeType='All')
   - Rules are evaluated in priority order, highest Priority value wins

3. **Default**: If no rules match, user cannot request the role

### New Stored Procedures:

**Team Management:**
- `jit.sp_Team_Create` - Create new team
- `jit.sp_Team_Update` - Update team metadata
- `jit.sp_Team_AddMember` - Add user to team
- `jit.sp_Team_RemoveMember` - Remove user from team
- `jit.sp_Team_ListMembers` - List all team members
- `jit.sp_Team_ListForUser` - List all teams for a user

**Eligibility Management:**
- `jit.sp_EligibilityRule_Create` - Create eligibility rule
- `jit.sp_EligibilityRule_Update` - Update eligibility rule
- `jit.sp_EligibilityRule_Delete` - Delete eligibility rule
- `jit.sp_EligibilityRule_ListForRole` - List all rules for a role

**Core Logic:**
- `jit.sp_User_Eligibility_Check` - Core eligibility resolution logic
  - Implements the priority-based checking described above
  - Called by `sp_Role_ListRequestable` and `sp_Request_Create`

**Updated Procedures:**
- `jit.sp_Role_ListRequestable` - Now uses `sp_User_Eligibility_Check` for multi-scope eligibility
- `jit.sp_Request_Create` - Now uses `sp_User_Eligibility_Check` for validation

### Frontend Impact:

**Admin Interface:**
- New "Teams" section for managing teams
- New "Eligibility Rules" section for managing role eligibility
  - Interface allows creating rules for:
    - Individual users
    - Entire departments
    - Entire divisions
    - Specific teams
    - All users (global rules)
- User management can now assign users to teams

**User Interface:**
- No changes to user-facing interface (eligibility is transparent)

**Approver Interface:**
- No changes (approvers only see requests, not eligibility rules)

---

## Implementation Notes

### Eligibility Rule Examples:

1. **Allow entire department:**
   - ScopeType='Department', ScopeValue='IT', CanRequest=1

2. **Allow specific team:**
   - ScopeType='Team', ScopeValue='5' (TeamId), CanRequest=1

3. **Allow entire division:**
   - ScopeType='Division', ScopeValue='Engineering', CanRequest=1

4. **Deny specific user (override):**
   - Use `jit.User_To_Role_Eligibility` table: UserId=X, RoleId=Y, CanRequest=0

5. **Allow everyone:**
   - ScopeType='All', ScopeValue=NULL, CanRequest=1

6. **Complex scenario:**
   - Division rule allows access
   - But team-specific rule denies it (higher priority)
   - Result: denied for that team

### Auto-Approval Examples (UPDATED with Seniority-Based Approval):

1. **Low-risk role (e.g., "Read-Only Reports"):**
   - RequiresApproval=0
   - Users in eligible scope can request and get immediate access

2. **High-risk role (e.g., "Full Database Access"):**
   - RequiresApproval=1, AutoApproveMinSeniority=NULL
   - Even eligible users must get manual approval regardless of seniority

3. **Role with seniority bypass (e.g., "Advanced Reports"):**
   - RequiresApproval=1, AutoApproveMinSeniority=3
   - Senior employees (level 3+) get instant access
   - Junior employees (level 1-2) require approval

4. **Pre-approved role (no approval needed):**
   - RequiresApproval=0 (AutoApproveMinSeniority is ignored)
   - Everyone gets instant access if eligible

---

## Migration Considerations

If migrating from the old plan:

1. **Existing `User_To_Role_Eligibility` data:**
   - Convert existing entries to `Role_Eligibility_Rules` with ScopeType='User'
   - Or keep as explicit overrides (recommended for backward compatibility)

2. **Role catalog:**
   - Set `RequiresApproval=1` for all existing roles (default)
   - Admin can change to 0 for roles that should be pre-approved

3. **AD Sync:**
   - Ensure AD sync captures `Division` field
   - Initialize teams from existing organizational structure if available

---

## 3. Seniority-Based Auto-Approval (NEW)

### Changes Made:

**A. `jit.Users` Table Enhancement:**
- **Added**: `SeniorityLevel` (int, nullable)
  - Numeric value representing user seniority (1 = most junior, higher numbers = more senior)
  - Can be synced from AD or manually set
  - Examples: 1=Junior, 2=Mid, 3=Senior, 4=Principal, 5=Director, etc.

**B. `jit.Roles` Table Enhancement:**
- **Added**: `AutoApproveMinSeniority` (int, nullable)
  - Minimum seniority level required for auto-approval bypass
  - If user's SeniorityLevel >= this value, request is auto-approved even if RequiresApproval=1
  - NULL means seniority-based bypass is disabled for this role

**C. `jit.sp_Request_Create` Procedure Logic Enhancement:**
- **Enhanced Auto-Approval Logic** (now 3-tier):
  1. **Tier 1 - Pre-Approved Role**: If `RequiresApproval = 0`, auto-approve all eligible users
  2. **Tier 2 - Seniority Bypass**: If `RequiresApproval = 1` AND `AutoApproveMinSeniority IS NOT NULL`:
     - Check if `user.SeniorityLevel >= role.AutoApproveMinSeniority`
     - If yes: Auto-approve (bypass manual approval)
     - If no: Require manual approval (status = 'Pending')
  3. **Tier 3 - Manual Approval**: If `RequiresApproval = 1` AND `AutoApproveMinSeniority IS NULL`, always require approval

**D. Audit Trail Enhancement:**
- Auto-approved requests log reason in audit:
  - 'PreApprovedRole' - Approved because RequiresApproval=0
  - 'SeniorityBypass' - Approved because user seniority meets threshold
- Status remains 'AutoApproved' for both cases

### Use Cases:

1. **Low-risk role with seniority bypass:**
   - RequiresApproval=1, AutoApproveMinSeniority=3
   - Senior employees (level 3+) get instant access
   - Junior employees still require approval

2. **High-risk role with no bypass:**
   - RequiresApproval=1, AutoApproveMinSeniority=NULL
   - Everyone requires approval regardless of seniority

3. **Pre-approved role (no approval needed):**
   - RequiresApproval=0 (AutoApproveMinSeniority is ignored)
   - Everyone gets instant access if eligible

### Benefits:

- Allows trusted senior employees faster access while maintaining controls for junior staff
- Reduces approval queue for common requests from senior users
- Maintains security: junior users still require oversight
- Flexible: can be enabled per-role basis
- Audit trail clearly indicates why request was auto-approved

---

## Benefits of All Changes

1. **Pre-Approved Roles:**
   - Reduces approval overhead for low-risk access
   - Faster access for common, safe roles
   - Maintains audit trail (AutoApproved status)
   - Still requires eligibility (security maintained)

2. **Seniority-Based Auto-Approval:**
   - Balances speed and security for senior staff
   - Reduces approval queue workload
   - Maintains oversight for junior staff
   - Flexible per-role configuration

3. **Multi-Scope Eligibility:**
   - More flexible than 1-to-1 user-role mapping
   - Easier to manage large organizations
   - Supports organizational hierarchies (Division → Department → Team)
   - Allows for bulk eligibility changes (change one rule, affects many users)
   - Still supports explicit user overrides when needed
