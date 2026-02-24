# Rebuild Backend (FastAPI) and Connect React Frontend

## Part 0: Clean Project Structure

The entire reworked project lives in a **new top-level folder** inside the repo root, separate from all previous iterations (`flask_app/`, old `frontend/`, loose files, etc.). Nothing from the old tree is referenced or imported -- only files that are needed by the fully working framework are created or copied (cleaned up) into the new tree.

### Folder layout

```
JIT-Access-for-Data/
  v2/                              <-- NEW clean root for the reworked project
    database/
      schema/                      # All CREATE TABLE scripts (updated with SCD-2 etc.)
      procedures/                  # All stored procedures (new + modified)
      test_data/                   # Seed / test data scripts
      jobs/                        # SQL Agent jobs (grant expiry etc.)
      01_Deploy_Everything.sql     # Master deploy script
      02_Cleanup_Everything.sql    # Master teardown script
    backend/
      main.py                      # FastAPI app entry point
      config.py                    # pydantic-settings, reads .env
      db.py                        # pyodbc helpers
      auth.py                      # get_current_user dependency
      routers/
        auth.py
        user.py
        approver.py
        admin.py
      schemas/
        common.py
        user.py
        role.py
        team.py
        request.py
        grant.py
        audit.py
      requirements.txt             # Python dependencies
      .env                         # (gitignored) DB_SERVER, DB_NAME, etc.
      .env.example                 # Template with placeholder values
    frontend/
      (copied from current frontend/, cleaned up per Part 3)
      package.json                 # cleaned deps (no @emotion, no @mui)
      vite.config.ts               # proxy points to FastAPI :8000
      src/
        main.tsx
        app/
          App.tsx                   # no role switcher, uses AuthContext only
          components/
            user/                   # UserOverview, UserRequestAccess, UserHistory, UserApprovals
            steward/                # StewardOverview, ManageRoles, ManageTeams, ManageUsers, AuditLogs
            shared/                 # MyActiveRoles
            ui/                     # shadcn/ui primitives
        api/
          client.ts
          types.ts
          endpoints.ts
        contexts/
          AuthContext.tsx
        styles/
          index.css
          tailwind.css
          theme.css
    README.md                       # How to set up and run the full stack
```

### What does NOT get copied into `v2/`

- `flask_app/` -- replaced entirely by `v2/backend/`
- Old top-level components (`Overview.tsx`, `AccessControl.tsx`, `AuditLogs.tsx` at component root, `UserManagement.tsx`, `figma/ImageWithFallback.tsx`)
- Any mock-data-only files or Figma artefacts
- Old `planttext_diagrams/`, `FRONTEND_BACKEND_GAPS.md`, `PRODUCT_FEATURE_PRIORITIES.md` and other iteration docs (stay in the repo root for reference but are not part of `v2/`)

### Why `v2/` and not in-place

- Clean separation from previous PoC iterations
- No risk of accidentally importing old Flask code or stale API types
- Easy to compare old vs new side-by-side during review
- The old code stays in the repo for reference until the team decides to archive it

---

## Part 1: User Stories

### Regular User

**US-1 Dashboard (UserOverview)**
As a regular user I want to see my active role grants (with role name, description, granted/expiry dates, status) and my pending requests on one dashboard, so I know at a glance what I have access to and what is in flight.

**US-2 Request Access (UserRequestAccess)**
As a regular user I want to browse roles I am eligible to request, search/sort/filter them, mark favourites (persisted in localStorage), select one or more roles, specify a duration (capped by the role's max), provide a justification and optional ticket reference, and submit the request. Auto-approvable requests should be granted immediately.

**US-3 History (UserHistory)**
As a regular user I want to see every request I ever made with its status, the roles requested, who approved/denied it, their comment, and the decision date. I want to filter by status and time range, and cancel any still-pending request.

### Approver

**US-4 Approvals queue (UserApprovals)**
As an approver I want to see all pending requests that I am authorised to approve, with requester name, email, department, requested roles, sensitivity level, duration, justification, and ticket reference. I want summary counts (pending, approved last 30d, rejected last 30d). I can approve (with optional comment), or reject (comment required).

### Data Steward / Admin

**US-5 Overview (StewardOverview)**
As a data steward/admin I want a KPI dashboard (total roles, sensitive roles, active grants, total users), a list of pending approvals with quick approve/reject, and a recent activity feed sourced from the audit log.

**US-6 Manage Roles (ManageRoles)**
As a data steward/admin I want to list all roles with their icon, colour, type (Public/Standard/Sensitive), enabled state, user count, and assigned DB-role permissions. I want to:

- Create/edit a role (name, description, type, icon, colour)
- Enable/disable a role
- Delete a role (soft-delete)
- View eligible + active users for a role
- Edit DB-role permissions via a dual-listbox (available vs assigned database roles)
- Edit eligibility rules: add/remove/edit rules scoped to User, Team, Division, or Department with per-rule max duration, min seniority, requiresJustification, requiresApproval

**US-7 Manage Teams (ManageTeams)**
As a data steward/admin I want to see all teams with name, description, department, member count, and associated roles. I want to create, edit, delete teams, and manage team members.

**US-8 Manage Users (ManageUsers)**
As a data steward/admin I want to list all users (searchable, filterable by department/role/status, paginated) showing name, email, department, status, and system-role flags (admin, steward, approver). I want to edit a user's system-role flags.

**US-9 Audit Logs (AuditLogs -- currently a placeholder)**
As a data steward/admin I want to see a searchable, filterable, paginated audit trail of all system events with timestamp, actor, event type, target, and structured details. I want to export logs.

**US-10 My Access (shared/MyActiveRoles)**
As a steward/admin I want the same "my active grants + pending requests" view that regular users get, tucked under the "My Access" submenu.

---

## Part 2: Styling Audit

- **No CSS modules found** -- all styling is Tailwind utility classes. No changes needed.
- **No styled-components usage found** -- `@emotion/react` and `@emotion/styled` are listed in `package.json` as dependencies but are **never imported**. They should be **removed from package.json** to keep the dependency tree clean.
- **MUI dependency** -- `@mui/material` and `@mui/icons-material` are in `package.json`. Verify whether any component imports them; if not, remove. The frontend primarily uses `lucide-react` for icons and `shadcn/ui` (Radix) for components.

---

## Part 3: Frontend Cleanup

### Remove role switcher

The demo `<select>` in `App.tsx` (around lines 132-142) and the local `userRole` / `handleRoleChange` state must be removed. The real role should come exclusively from `AuthContext` (which derives it from `/api/me`).

### Remove unused top-level components

When copying the frontend into `v2/frontend/`, do **not** include these original Figma-generated pages that are not wired into the navigation:

- `Overview.tsx`
- `AccessControl.tsx`
- `AuditLogs.tsx` (the top-level one; the steward one stays)
- `UserManagement.tsx`
- `figma/ImageWithFallback.tsx`

### Remove "lead" field from ManageTeams

The ManageTeams component displays a `lead` field per team. There is no `LeadUserId` in the database and we are not adding one. Remove the `lead` property from the team interface, the mock data, the search filter, and any UI references in `v2/frontend/src/app/components/steward/ManageTeams.tsx`.

### Remove mock data from every page component

Every component in `user/`, `steward/`, `shared/` has hardcoded arrays. Replace with `useEffect` + API fetch (or a custom hook). Components affected:

- `UserOverview.tsx` -- `activeRolesRaw`, `pendingRequests`
- `UserRequestAccess.tsx` -- `availableRoles`
- `UserHistory.tsx` -- `historyItems`
- `UserApprovals.tsx` -- `approvalRequests`
- `StewardOverview.tsx` -- `kpiData`, `pendingApprovals`, `recentActivity`
- `ManageRoles.tsx` -- `roles`, `mockRoleUsers`, `mockDatabaseRoles`, `mockUsers`, `mockTeams`, `mockDivisions`, `mockDepartments`
- `ManageTeams.tsx` -- `teams`
- `ManageUsers.tsx` -- `users`
- `MyActiveRoles.tsx` -- `activeRoles`, `pendingRequests`

---

## Part 4: Database Schema Changes

All SQL scripts are created fresh in `v2/database/schema/` and `v2/database/procedures/` (no migration scripts -- PoC). These are the canonical, clean versions of every table and SP.

### 4a. Audit-compliant versioning (SCD-2)

Three configuration tables need **Slowly Changing Dimension Type 2** versioning so that past access decisions are always traceable to the exact configuration that was in effect.

**Pattern applied to each table**: every row gets these columns:

```sql
VersionId       BIGINT IDENTITY  -- new PK (the original business key becomes a non-unique grouping column)
IsActive        BIT NOT NULL DEFAULT 1,
ValidFromUtc    DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
ValidToUtc      DATETIME2 NULL,     -- NULL = current version
```

On **edit**: the SP sets `IsActive = 0, ValidToUtc = GETUTCDATE()` on the old row, then INSERTs a new row with updated values and `IsActive = 1, ValidFromUtc = GETUTCDATE()`.
On **soft-delete**: the SP sets `IsActive = 0, ValidToUtc = GETUTCDATE()` (no new row inserted).
All **read queries** filter on `IsActive = 1` to get the current state.

**Tables receiving this pattern:**

**`jit.Roles`** (`database/schema/02_Create_Roles.sql`)
- Add `RoleVersionId BIGINT IDENTITY` as new PK; `RoleId` becomes a non-unique business key (add a non-clustered index)
- Add `IsActive`, `ValidFromUtc`, `ValidToUtc` versioning columns
- Also add new feature columns: `SensitivityLevel NVARCHAR(50) DEFAULT 'Standard'`, `IconName NVARCHAR(100) DEFAULT 'Database'`, `IconColor NVARCHAR(100) DEFAULT 'bg-blue-500'`

**`jit.Role_Eligibility_Rules`** (`database/schema/07_Create_Role_Eligibility_Rules.sql`)
- Add `EligibilityRuleVersionId BIGINT IDENTITY` as new PK; `EligibilityRuleId` becomes a non-unique business key
- Add `IsActive`, `ValidFromUtc`, `ValidToUtc` versioning columns
- Also add per-rule override columns: `MinSeniorityLevel INT NULL`, `MaxDurationMinutesOverride INT NULL`, `RequiresJustificationOverride BIT NULL`, `RequiresApprovalOverride BIT NULL`

**`jit.Role_To_DB_Roles`** (`database/schema/04_Create_Role_To_DB_Roles.sql`)
- Add `RoleDbRoleVersionId BIGINT IDENTITY` as new PK; the composite `(RoleId, DbRoleId)` becomes a non-unique business key
- Add `IsActive`, `ValidFromUtc`, `ValidToUtc` versioning columns

**Tables that do NOT need SCD-2** (already immutable or have their own temporal tracking):
- `jit.Requests`, `jit.Approvals`, `jit.Grants`, `jit.AuditLog` -- insert-only / already time-stamped
- `jit.User_Teams` -- already has `IsActive` and temporal columns (see 4d below for rename)
- `jit.Users`, `jit.Teams`, `jit.DB_Roles` -- changes are audit-logged but don't drive access grant decisions the same way

### 4b. Grant/Request linking to historical versions

When a grant is issued, the system must record which version of the configuration was in effect. This uses a **dual approach**: FK references for queryability + JSON snapshot for human-readable evidence.

**Add to `jit.Grants`** (`database/schema/12_Create_Grants.sql`):
```sql
RoleVersionId               BIGINT NULL,  -- FK to jit.Roles.RoleVersionId (the exact version at grant time)
ConfigSnapshotJson          NVARCHAR(MAX) NULL  -- JSON snapshot of role + eligibility rule + DB role mappings at grant time
```

**Add to `jit.Requests`** (`database/schema/10_Create_Requests.sql`):
```sql
EligibilitySnapshotJson     NVARCHAR(MAX) NULL  -- JSON snapshot of the eligibility rules that matched at request time
```

The `sp_Grant_Issue` and `sp_Request_Create` SPs will populate these fields by reading the active versions at execution time and serializing the relevant config into JSON.

This means an auditor can:
1. **Query by FK**: `SELECT * FROM jit.Roles WHERE RoleVersionId = @grant.RoleVersionId` to get the exact role definition
2. **Read the snapshot**: `SELECT ConfigSnapshotJson FROM jit.Grants WHERE GrantId = @id` for a self-contained evidence record

### 4c. Add feature columns (non-versioning)

No additional schema changes beyond what is already covered in 4a above.

### 4d. Standardise temporal column names

All tables that use a close-and-insert or active/inactive pattern must use the same column names: **`ValidFromUtc`** and **`ValidToUtc`**. This makes queries, SP templates, and auditing consistent.

**`jit.User_Teams`** (`database/schema/06_Create_User_Teams.sql`) currently uses:
- `AssignedUtc` -- rename to **`ValidFromUtc`**
- `RemovedUtc` -- rename to **`ValidToUtc`**

Since this is PoC (no migration scripts), just update the CREATE script directly. All SPs and queries that reference `AssignedUtc` or `RemovedUtc` on `User_Teams` must be updated to use the new names. Affected SPs to check:
- `sp_Team_SetMembers` (new SP -- write it with the standard names from the start)
- Any existing SP or query that reads `User_Teams` membership (e.g. `sp_Role_ListRequestable`, `sp_Request_ListPendingForApprover` both join `User_Teams` and reference the column in eligibility checks -- verify and update)

---

## Part 5: New / Modified Stored Procedures

All procedures in `database/procedures/`.

### 5a. Modify existing SPs (column gaps)

**`sp_Grant_ListActiveForUser`** -- add: `g.RoleId`, `r.Description AS RoleDescription`, alias `ValidFromUtc AS GrantedUtc`, `ValidToUtc AS ExpiryUtc`, `r.SensitivityLevel`

**`sp_Request_ListForUser`** -- add: join `jit.Users approver` via `jit.Approvals`, return `approver.DisplayName AS ApproverName`, `a.DecisionUtc`, alias `a.DecisionComment`. For revoked info: join `jit.Grants` to get `RevokedUtc`, `RevokeReason`, and revoked-by user.

**`sp_Role_ListRequestable`** -- alias `Description AS RoleDescription`, add `r.SensitivityLevel`, `r.IconName`, `r.IconColor`

**`sp_Request_ListPendingForApprover`** -- add `u.Email AS RequesterEmail`, `r.SensitivityLevel` (aggregated, e.g. MAX sensitivity across requested roles)

### 5b. Modify existing SPs (versioning)

**`sp_Grant_Issue`** -- When issuing a grant, look up the current `RoleVersionId` from `jit.Roles WHERE RoleId = @RoleId AND IsActive = 1`, store it on the grant row. Build a JSON snapshot of the role definition + DB role mappings + matched eligibility rule and write it to `ConfigSnapshotJson`.

**`sp_Request_Create`** -- When creating a request, build a JSON snapshot of the eligibility rules that matched for each requested role and write it to `EligibilitySnapshotJson`.

### 5c. New SPs needed

All CRUD SPs for versioned tables must follow the **close-and-insert** pattern: on update, set `IsActive = 0, ValidToUtc = GETUTCDATE()` on the old row, then INSERT a new active row. On delete, just close the old row. Read SPs always filter `IsActive = 1`.

| SP Name                       | Purpose                                                           |
| ----------------------------- | ----------------------------------------------------------------- |
| `sp_Role_Create`              | Insert into `jit.Roles` with new columns (new active version)     |
| `sp_Role_Update`              | Close current version, insert new version with updated values     |
| `sp_Role_Delete`              | Close current version (soft-delete, no new row)                   |
| `sp_Role_ToggleEnabled`       | Flip `IsEnabled`                                                  |
| `sp_Role_ListUsers`           | List eligible + active-grant users for a role                     |
| `sp_Role_GetDbRoles`          | Get assigned DB roles for a role (from `Role_To_DB_Roles`)        |
| `sp_Role_SetDbRoles`          | Close old active mappings, insert new active mappings (versioned) |
| `sp_Role_GetEligibilityRules` | Get eligibility rules for a role                                  |
| `sp_Role_SetEligibilityRules` | Close old active rules, insert new active rules (versioned)       |
| `sp_DbRole_ListAvailable`     | List all DB roles from `jit.DB_Roles`                             |
| `sp_Team_Create`              | Insert team                                                       |
| `sp_Team_Update`              | Update team                                                       |
| `sp_Team_Delete`              | Soft-delete team                                                  |
| `sp_Team_ListWithStats`       | List teams with member count + associated role count              |
| `sp_Team_GetMembers`          | List members of a team                                            |
| `sp_Team_SetMembers`          | Add/remove team members                                           |
| `sp_User_UpdateSystemRoles`   | Update `IsAdmin`, `IsApprover`, `IsDataSteward` flags             |
| `sp_User_ListPaginated`       | Paginated + filterable user list                                  |
| `sp_AuditLog_ListPaginated`   | Paginated + filterable audit log with actor display name          |
| `sp_AuditLog_GetStats`        | Count by event type for the stats bar                             |
| `sp_Stats_Dashboard`          | Aggregate KPIs for steward overview                               |
| `sp_LookupValues`             | Return lists for dropdowns: users, teams, divisions, departments  |

---

## Part 6: FastAPI Backend

### 6a. Project structure

All backend code lives under `v2/backend/` (see Part 0). The old `flask_app/` is not touched.

```
v2/backend/
  main.py                 # FastAPI app, CORS, lifespan
  config.py               # Settings via pydantic-settings (reads .env)
  db.py                   # pyodbc connection pool + execute_procedure / execute_query helpers
  auth.py                 # Dependency: get_current_user, role checkers
  routers/
    auth.py               # GET /api/me
    user.py               # grants, requests, requestable roles
    approver.py           # pending, approve, deny, request detail
    admin.py              # roles CRUD, teams CRUD, users, audit, stats, lookups
  schemas/
    user.py               # Pydantic response models
    role.py
    team.py
    request.py
    grant.py
    audit.py
    common.py             # ApiResponse wrapper
  .env                    # DB_SERVER, DB_NAME, DB_DRIVER, DB_USERNAME, DB_PASSWORD, SECRET_KEY, CORS_ORIGINS
```

### 6b. Key design decisions

- **Auth**: Same Windows auth model via `X-Remote-User` header + `JIT_FAKE_USER` env var for dev. Implemented as a FastAPI dependency (`Depends(get_current_user)`).
- **DB**: `pyodbc` with connection pooling. Helper functions `execute_sp(name, params)` and `execute_query(sql, params)` returning `list[dict]`.
- **All business logic stays in T-SQL** -- FastAPI is a thin pass-through that calls SPs and returns JSON.
- **Response envelope**: `{ "ok": true, "data": ... }` / `{ "ok": false, "error": "..." }` matching the existing `ApiResponse` interface in the frontend.
- **Vite proxy**: Update `frontend/vite.config.ts` to proxy `/api` to FastAPI (default `http://127.0.0.1:8000`).
- **No hardcoded env vars**: All config via `.env` loaded through `pydantic-settings`.

### 6c. API Endpoints (complete list)

**Auth**
- `GET /api/me` -- current user + role flags

**User**
- `GET /api/user/grants` -- active grants
- `GET /api/user/requests` -- request history
- `GET /api/roles/requestable` -- eligible roles
- `POST /api/requests` -- create request `{ roleIds, durationMinutes, justification, ticketRef? }`
- `POST /api/requests/{id}/cancel` -- cancel pending request

**Approver**
- `GET /api/approver/pending` -- pending queue
- `GET /api/approver/requests/{id}` -- request detail
- `POST /api/requests/{id}/approve` -- approve `{ comment? }`
- `POST /api/requests/{id}/deny` -- deny `{ comment }`

**Admin / Management** (requires admin OR data steward)
- `GET /api/admin/stats` -- dashboard KPIs
- `GET /api/admin/lookups` -- dropdown data (users, teams, divisions, departments)
- **Roles**
  - `GET /api/admin/roles` -- list all
  - `POST /api/admin/roles` -- create
  - `PUT /api/admin/roles/{id}` -- update
  - `DELETE /api/admin/roles/{id}` -- soft-delete
  - `POST /api/admin/roles/{id}/toggle` -- enable/disable
  - `GET /api/admin/roles/{id}/users` -- eligible + active users
  - `GET /api/admin/roles/{id}/db-roles` -- assigned DB roles
  - `PUT /api/admin/roles/{id}/db-roles` -- set DB roles `{ dbRoleIds[] }`
  - `GET /api/admin/roles/{id}/eligibility-rules` -- list rules
  - `PUT /api/admin/roles/{id}/eligibility-rules` -- replace rules `{ rules[] }`
- **DB Roles**
  - `GET /api/admin/db-roles` -- list all available DB roles
- **Teams**
  - `GET /api/admin/teams` -- list with stats
  - `POST /api/admin/teams` -- create
  - `PUT /api/admin/teams/{id}` -- update
  - `DELETE /api/admin/teams/{id}` -- soft-delete
  - `GET /api/admin/teams/{id}/members` -- list members
  - `PUT /api/admin/teams/{id}/members` -- set members `{ userIds[] }`
- **Users**
  - `GET /api/admin/users` -- paginated list `?search=&department=&role=&status=&page=&pageSize=`
  - `PUT /api/admin/users/{id}/system-roles` -- update flags `{ isAdmin, isApprover, isDataSteward }`
- **Audit**
  - `GET /api/admin/audit-logs` -- paginated `?search=&eventType=&startDate=&endDate=&page=&pageSize=`

---

## Part 7: Frontend API Wiring

### 7a. Update API client

Rewrite `frontend/src/api/client.ts`, `frontend/src/api/types.ts`, and `frontend/src/api/endpoints.ts` to match the new endpoint list. Add missing type interfaces for all response shapes.

### 7b. Per-component wiring

Each component replaces its mock `useState` arrays with:

1. A loading state
2. A `useEffect` that calls the appropriate endpoint
3. Error handling

Action handlers (approve, deny, create, edit, delete, toggle) call the corresponding POST/PUT/DELETE endpoint then refresh the list.

### 7c. Vite proxy

Update the proxy target in `v2/frontend/vite.config.ts` to point to FastAPI's port 8000.

---

## Part 8: Implementation Order

The recommended build order, designed so each step is independently testable:

0. **Scaffold `v2/` folder** -- create the clean directory tree (see Part 0). Copy and clean the frontend into `v2/frontend/`, create `v2/backend/` and `v2/database/` from scratch. Write `v2/README.md` with setup instructions.
1. **Schema changes** -- create updated CREATE scripts in `v2/database/schema/`, redeploy DB
2. **New SPs** -- all listed in Part 5c, create in `v2/database/procedures/`, test with SSMS
3. **Modify existing SPs** -- Part 5a and 5b, save updated versions in `v2/database/procedures/`, fix column gaps + versioning
4. **FastAPI scaffold** -- build out `v2/backend/` with project structure, config, DB helpers, auth dependency, `requirements.txt`, `.env.example`
5. **FastAPI read endpoints** -- `/api/me`, all GET routes, verify with browser/Postman
6. **FastAPI write endpoints** -- all POST/PUT/DELETE routes
7. **Frontend cleanup** -- in `v2/frontend/`: remove switcher, remove unused components, remove "lead" from ManageTeams, remove @emotion/MUI deps
8. **Frontend wiring** -- connect each page to the API, replace mock data
9. **Build AuditLogs page** -- currently a placeholder, build the real component

---

## Appendix: Todo Checklist

- [ ] Scaffold `v2/` clean project tree: create `v2/database/`, `v2/backend/`, copy+clean `v2/frontend/`, write `v2/README.md`
- [ ] Create updated SQL CREATE scripts in `v2/database/schema/`: SCD-2 versioning on Roles, Role_Eligibility_Rules, Role_To_DB_Roles; add SensitivityLevel/IconName/IconColor to Roles; add override columns to Rules; add version FK + snapshot JSON columns to Grants and Requests; rename User_Teams.AssignedUtc/RemovedUtc to ValidFromUtc/ValidToUtc
- [ ] Create ~20 new stored procedures in `v2/database/procedures/` for CRUD operations (roles, teams, users, audit, lookups, stats); role/rule/db-role CRUD SPs use SCD-2 close-and-insert pattern
- [ ] Update existing SPs in `v2/database/procedures/`: add missing columns/aliases to sp_Grant_ListActiveForUser, sp_Request_ListForUser, sp_Role_ListRequestable, sp_Request_ListPendingForApprover; update sp_Grant_Issue and sp_Request_Create to populate version FK + JSON snapshots
- [ ] Create FastAPI project structure in `v2/backend/`: main.py, config.py (pydantic-settings + .env), db.py (pyodbc helpers), auth.py (X-Remote-User dependency), requirements.txt, .env.example
- [ ] Implement all GET endpoints: /api/me, user grants/requests/requestable, approver pending/detail, admin roles/teams/users/audit/stats/lookups/db-roles
- [ ] Implement all POST/PUT/DELETE endpoints: create/edit/delete roles+teams, toggle role, set db-roles, set eligibility-rules, set team members, update user system-roles, approve/deny/cancel requests
- [ ] Frontend cleanup in `v2/frontend/`: remove role switcher from App.tsx, delete unused components (Overview, AccessControl, top-level AuditLogs, UserManagement, ImageWithFallback), remove "lead" from ManageTeams, remove @emotion and @mui from package.json
- [ ] Rewrite `v2/frontend/src/api/` (client.ts, types.ts, endpoints.ts) to match new FastAPI endpoints and response shapes
- [ ] Replace mock data in all 9 page components with useEffect + API calls, wire action handlers to POST/PUT/DELETE endpoints
- [ ] Build the real AuditLogs steward component in `v2/frontend/` (currently placeholder): paginated table, search, filters, export
- [ ] Write `v2/README.md` with setup instructions for database, backend, and frontend
