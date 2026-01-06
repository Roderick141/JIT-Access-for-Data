# JIT Access Framework

Just-In-Time Access Framework for SQL Server Database Access Control

## Overview

This framework provides a comprehensive solution for managing temporary, time-bound access to SQL Server database resources through a role-based access control system with automatic expiration and approval workflows.

## Features

- **Identity Management**: Windows Authentication integration with AD enrichment (no auto-user creation)
- **Role-Based Access**: Requestable business roles mapped to database roles
- **Multi-Scope Eligibility**: Support for user, department, division, team, and global eligibility rules
- **Auto-Approval**: Pre-approved roles and seniority-based auto-approval
- **Approval Workflow**: Manual approval for sensitive roles
- **Automatic Expiration**: SQL Agent jobs automatically revoke expired access
- **Comprehensive Audit**: Complete audit trail of all access grants and changes
- **Flask Web Interface**: Dark mode web application for user requests, approvals, and administration
- **Service Account Authentication**: Database connections use SQL Server Authentication with service account
- **Role-Based Navigation**: User, Approver, and Admin portals with appropriate access levels

## Directory Structure

```
jit_framework/
├── database/
│   ├── schema/          # Database table creation scripts
│   ├── procedures/      # Stored procedures
│   ├── jobs/           # SQL Agent job scripts
│   └── test_data/      # Test data scripts
└── flask_app/
    ├── static/         # CSS, JavaScript
    ├── templates/      # HTML templates
    ├── utils/          # Utility modules
    ├── app.py          # Main Flask application
    └── config.py       # Configuration
```

## Installation

### Prerequisites

- SQL Server 2016 or later
- Python 3.8 or later
- ODBC Driver for SQL Server
- Service account for database connections

### Database Setup

1. Create the database (if not exists):
   ```sql
   CREATE DATABASE [DMAP_JIT_Permissions]
   ```

2. Create the service account login and user:
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

3. Run schema creation scripts in order using master script:
   ```sql
   :r "database/schema/99_Create_All_Tables.sql"
   ```
   
   Or run individually:
   - `database/schema/00_Create_jit_Schema.sql`
   - `database/schema/01_Create_Users.sql` through `14_Create_AuditLog.sql`

4. Create stored procedures using master script:
   ```sql
   :r "database/procedures/99_Create_All_Procedures.sql"
   ```

5. Create SQL Agent jobs from `database/jobs/` directory

6. Set up admin users:
   ```sql
   UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\adminuser';
   ```

### Flask Application Setup

1. Install Python dependencies:
   ```bash
   cd flask_app
   pip install -r requirements.txt
   ```

2. Configure environment variables (create `.env` file from `.env.example`):
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

3. Run the application:
   ```bash
   python app.py
   ```

4. Access the application at `http://localhost:5000`

## Usage

### User Portal

- View active grants and expiry dates
- Request access to eligible roles
- View request history
- Cancel pending requests

**Access**: All authenticated users

### Approver Portal

- View pending approval requests
- Approve or deny requests with comments
- Review requester details and justification

**Access**: Users listed in `jit.Role_Approvers` table

### Admin Portal

- Manage role catalog
- Configure teams and eligibility rules
- View audit reports
- Manage users (set admin flags, view user details)

**Access**: Users with `IsAdmin = 1` in `jit.Users` table

## User Management

### Creating Users

Users must be created manually or via AD sync before they can access the application. The framework does not auto-create users.

**Manual Creation**:
```sql
INSERT INTO jit.Users (LoginName, DisplayName, GivenName, Surname, Email, Department, Division, IsActive)
VALUES ('DOMAIN\username', 'Display Name', 'First', 'Last', 'user@domain.com', 'IT', 'Engineering', 1);
```

**AD Sync**: Use `sp_User_SyncFromAD` stored procedure with AD staging table

### Setting Up Approvers

```sql
INSERT INTO jit.Role_Approvers (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
FROM jit.Roles r
CROSS JOIN jit.Users u
WHERE r.RoleName = 'Role Name'
AND u.LoginName = 'DOMAIN\approverusername';
```

### Setting Up Admins

```sql
UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\adminuser';
```

## Security Considerations

- Database connections use SQL Server Authentication with service account (not Windows Authentication)
- User identification uses Windows username from environment/request headers
- Users must exist in database before accessing application (no auto-creation)
- Only whitelisted roles can be managed by the framework
- Direct grants to users are monitored and reported
- Complete audit trail of all operations
- Automatic expiration of access grants
- Reconciliation jobs detect and report drift
- Role-based access control: Users see user pages, Approvers see user+approver pages, Admins see all pages

## Documentation

- **SERVICE_ACCOUNT_SETUP.md**: Detailed service account setup guide
- **FLASK_SETUP_GUIDE.md**: Flask application setup and configuration
- **AUTHENTICATION_EXPLAINED.md**: Detailed authentication and authorization explanation
- **CHANGES_SUMMARY.md**: Summary of recent changes and updates

## Notes

- The framework uses SQL Server Authentication with a service account for database connections
- User identification uses Windows username (from environment variables or request headers)
- Users must be created manually or via AD sync - no auto-creation
- SQL Agent jobs must be configured for automatic expiration
- Review and configure security permissions for the `jit` schema and service account
- Store service account credentials securely (use environment variables, not hardcoded values)

## License

[Your License Here]
