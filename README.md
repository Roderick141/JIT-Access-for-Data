# JIT Access Framework

Just-In-Time Access Framework for SQL Server Database Access Control

## Overview

A comprehensive solution for managing temporary, time-bound access to SQL Server database resources through a role-based access control system with automatic expiration and approval workflows. Features a modern Flask web interface with dark mode design.

## Features

- **Multi-Role Requests**: Request multiple roles in a single request
- **Identity Management**: Windows Authentication integration with AD enrichment (no auto-user creation)
- **Role-Based Access**: Requestable business roles mapped to database roles
- **Multi-Scope Eligibility**: Support for user, department, division, team, and global eligibility rules
- **Auto-Approval**: Pre-approved roles and seniority-based auto-approval
- **Division + Seniority Approval Model**: Approvers can approve requests from colleagues in their division if they have sufficient seniority
- **Automatic Expiration**: SQL Agent jobs automatically revoke expired access
- **Comprehensive Audit**: Complete audit trail of all access grants and changes
- **Flask Web Interface**: Dark mode web application for user requests, approvals, and administration
- **Service Account Authentication**: Database connections use SQL Server Authentication with service account

## Technology Stack

- **Backend Database**: SQL Server (T-SQL stored procedures, tables, SQL Agent jobs)
- **Frontend**: Python Flask web application
- **Styling**: HTML5, CSS3 with minimalist dark mode design
- **Database Connection**: SQL Server Authentication with service account
- **User Identification**: Windows username (from environment variables or request headers)
- **Python Dependencies**: Flask, pyodbc, python-dotenv

## Quick Start

### Prerequisites

- SQL Server 2016 or later
- Python 3.8 or later
- ODBC Driver for SQL Server
- Service account for database connections

### Database Setup

1. **Create Database** (if not exists):
   ```sql
   CREATE DATABASE [DMAP_JIT_Permissions]
   ```

2. **Create Service Account**:
   ```sql
   -- Create login
   CREATE LOGIN [JIT_ServiceAccount] WITH PASSWORD = 'YourStrongPassword123!';
   
   -- Create user in database
   USE [DMAP_JIT_Permissions];
   CREATE USER [JIT_ServiceAccount] FOR LOGIN [JIT_ServiceAccount];
   
   -- Grant permissions
   GRANT EXECUTE ON SCHEMA::jit TO [JIT_ServiceAccount];
   GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::jit TO [JIT_ServiceAccount];
   ```

3. **Deploy Schema and Procedures**:
   ```bash
   sqlcmd -S YourServerName -d DMAP_JIT_Permissions -i "database/01_Deploy_Everything.sql"
   ```

4. **Set Up Admin Users**:
   ```sql
   UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\admin.user';
   ```

### Flask Application Setup

1. **Install Dependencies**:
   ```bash
   cd flask_app
   pip install -r requirements.txt
   ```

2. **Configure Environment Variables** (create `.env` file):
   ```env
   # Database Connection (Service Account)
   DB_SERVER=your_sql_server
   DB_NAME=DMAP_JIT_Permissions
   DB_DRIVER={ODBC Driver 17 for SQL Server}
   DB_USERNAME=JIT_ServiceAccount
   DB_PASSWORD=YourStrongPassword123!
   
   # Application Settings
   SECRET_KEY=your-secret-key-here
   FLASK_ENV=development
   DEBUG=True
   ```

3. **Run Application**:
   ```bash
   python app.py
   ```

4. **Access**: Navigate to `http://localhost:5000`

## User Roles and Access

### Regular Users
- View active grants and expiry dates
- Request access to eligible roles (single or multiple roles per request)
- View request history
- Cancel pending requests

### Approvers
- All regular user access
- View pending approval requests (only requests where they can approve ALL roles)
- Approve or deny requests with comments
- Review requester details and justification

**Approver Eligibility**: Users can approve if:
- They are an admin (`IsAdmin = 1`), OR
- They are in the same division as the requester AND have sufficient seniority (`SeniorityLevel >= role.AutoApproveMinSeniority` AND requester's seniority < approver's seniority)

### Administrators
- All approver access
- Manage role catalog
- Configure teams and eligibility rules
- View audit reports
- Manage users (set admin flags, view user details)

## Key Concepts

### Multi-Role Requests

Users can request multiple roles in a single request:
- Minimum duration is automatically calculated (minimum of all selected roles' max durations)
- Ticket is required if ANY selected role requires it
- All roles are approved/denied together (all-or-nothing)
- Each role gets its own grant when approved

### Auto-Approval Logic

Requests are auto-approved if:
1. **Pre-approved roles**: All selected roles have `RequiresApproval = 0`
2. **Seniority bypass**: User's `SeniorityLevel >= all roles' AutoApproveMinSeniority`
3. **Otherwise**: Request status = 'Pending' and requires manual approval

### Approval Model

Approvers can approve requests where they can approve ALL roles in the request:
- **Admin override**: Admins can approve any request
- **Division + Seniority**: Approver and requester must be in same division, AND approver's seniority >= all roles' `AutoApproveMinSeniority`, AND requester's seniority < approver's seniority

### Eligibility Rules

Multi-scope eligibility system:
- **Priority 1**: User-specific overrides (`User_To_Role_Eligibility`)
- **Priority 2**: Scope-based rules (`Role_Eligibility_Rules`) by priority:
  - User-specific rules
  - Team rules (user must be active member)
  - Department rules
  - Division rules
  - All scope rules (lowest priority)

## Directory Structure

```
JIT-Access-for-Data/
├── database/
│   ├── schema/              # Database table creation scripts
│   │   ├── 00_Create_jit_Schema.sql
│   │   ├── 01_Create_Users.sql
│   │   ├── 02_Create_Roles.sql
│   │   ├── ...
│   │   ├── 15_Create_Request_Roles.sql (multi-role support)
│   │   └── 99_Create_All_Tables.sql
│   ├── procedures/          # Stored procedures
│   │   ├── sp_User_*.sql
│   │   ├── sp_Role_*.sql
│   │   ├── sp_Request_*.sql
│   │   ├── sp_Grant_*.sql
│   │   └── 99_Create_All_Procedures.sql
│   ├── jobs/               # SQL Agent job scripts
│   │   └── job_ExpireGrants.sql
│   ├── test_data/          # Test data scripts
│   │   ├── 09_Insert_Test_Requests.sql
│   │   ├── 09a_Insert_Test_Request_Roles.sql
│   │   └── 99_Insert_All_Test_Data.sql
│   ├── 01_Deploy_Everything.sql
│   └── 02_Cleanup_Everything.sql
└── flask_app/
    ├── app.py              # Main Flask application
    ├── config.py           # Configuration
    ├── requirements.txt    # Python dependencies
    ├── static/
    │   └── css/
    │       └── darkmode.css
    ├── templates/          # HTML templates
    │   ├── base.html
    │   ├── login.html
    │   ├── user/
    │   ├── approver/
    │   └── admin/
    └── utils/
        ├── auth.py         # Authentication utilities
        └── db.py           # Database connection utilities
```

## Deployment

### Full Deployment

```bash
sqlcmd -S YourServerName -d DMAP_JIT_Permissions -i "database/01_Deploy_Everything.sql"
```

This script will:
1. Create all database tables (schema)
2. Create all stored procedures
3. Optionally insert test data (commented out by default)

### Cleanup (Remove Everything)

**WARNING**: This deletes all data!

```bash
sqlcmd -S YourServerName -d DMAP_JIT_Permissions -i "database/02_Cleanup_Everything.sql"
```

## User Management

### Creating Users

Users must be created manually or via AD sync before accessing the application. The framework does not auto-create users.

**Manual Creation**:
```sql
INSERT INTO jit.Users (LoginName, DisplayName, GivenName, Surname, Email, Department, Division, SeniorityLevel, IsActive)
VALUES ('DOMAIN\username', 'Display Name', 'First', 'Last', 'user@domain.com', 'IT', 'Engineering', 3, 1);
```

**AD Sync**: Use `sp_User_SyncFromAD` stored procedure with AD staging table

### Setting Up Approvers

Approvers are determined automatically based on:
- Division membership (must match requester's division)
- Seniority level (must be >= role's `AutoApproveMinSeniority`)
- Seniority comparison (must be higher than requester)

No manual setup required - approvers see the approval page automatically if they meet criteria.

### Setting Up Admins

```sql
UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\adminuser';
```

## Development Testing

In development, the Flask app uses the `USERNAME` environment variable to identify users. Test as different users:

**Windows PowerShell**:
```powershell
$env:USERNAME = "DOMAIN\john.smith"
cd flask_app
python app.py
```

**Windows Command Prompt**:
```cmd
set USERNAME=DOMAIN\john.smith
cd flask_app
python app.py
```

## Security Considerations

- Database connections use SQL Server Authentication with service account (not Windows Authentication)
- User identification uses Windows username from environment/request headers
- Users must exist in database before accessing application (no auto-creation)
- Only whitelisted roles can be managed by the framework
- Complete audit trail of all operations
- Automatic expiration of access grants
- Role-based access control: Users see user pages, Approvers see user+approver pages, Admins see all pages

## Database Schema

### Core Tables

- **Users**: User identity, AD attributes, `IsAdmin`, `SeniorityLevel`, `Division`, `Department`
- **Roles**: Business roles with `RequiresApproval`, `AutoApproveMinSeniority`, eligibility rules
- **Requests**: Access requests (no RoleId - uses `Request_Roles` junction table)
- **Request_Roles**: Many-to-many relationship between Requests and Roles
- **Grants**: Active access grants (one per role)
- **Approvals**: Approval decisions
- **AuditLog**: Complete audit trail

### Key Indexes

- `Users`: LoginName (unique), IsActive, IsAdmin, Division+SeniorityLevel (composite)
- `Roles`: RoleName (unique), IsEnabled, RequiresApproval+AutoApproveMinSeniority (composite)
- `Requests`: UserId, Status (filtered for Pending/AutoApproved)
- `Request_Roles`: RequestId, RoleId

## Stored Procedures

### Core Procedures

- **Identity**: `sp_User_ResolveCurrentUser`, `sp_User_GetByLogin`, `sp_User_Eligibility_Check`
- **Roles**: `sp_Role_ListRequestable` (filters by eligibility, excludes active grants/pending requests)
- **Requests**: `sp_Request_Create` (supports multiple roles), `sp_Request_GetRoles`, `sp_Request_ListForUser`, `sp_Request_ListPendingForApprover`
- **Approval**: `sp_Approver_CanApproveRequest` (checks ALL roles), `sp_Request_Approve`, `sp_Request_Deny`
- **Grants**: `sp_Grant_Issue`, `sp_Grant_Expire`, `sp_Grant_ListActiveForUser`

## Testing

Test data scripts are available in `database/test_data/`:
- Includes single-role and multi-role request examples
- Various statuses (Pending, AutoApproved, Approved, Denied)
- Users with different seniority levels

To deploy test data:
```bash
# Uncomment test data section in 01_Deploy_Everything.sql, or:
sqlcmd -S YourServerName -d DMAP_JIT_Permissions -i "database/test_data/99_Insert_All_Test_Data.sql"
```

## License

[Your License Here]
