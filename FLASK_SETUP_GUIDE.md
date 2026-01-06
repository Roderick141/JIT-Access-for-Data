# Flask Application Setup and Authentication Guide

## 1. Database Connection Configuration

### Environment Variables

Create a `.env` file in the `flask_app` directory with the following settings:

```env
# Database Connection (Service Account)
DB_SERVER=your_sql_server_name_or_ip
DB_NAME=DMAP_JIT_Permissions
DB_DRIVER={ODBC Driver 17 for SQL Server}
DB_USERNAME=your_service_account_username
DB_PASSWORD=your_service_account_password

# Application Settings
SECRET_KEY=your-secret-key-here-change-in-production
FLASK_ENV=development
DEBUG=True
```

### Configuration Options Explained

**DB_SERVER**: 
- Your SQL Server instance name (e.g., `localhost`, `localhost\SQLEXPRESS`, `192.168.1.100`, or `SERVERNAME\INSTANCE`)
- Examples:
  - `localhost` - Local default instance
  - `localhost\SQLEXPRESS` - Local named instance
  - `SERVER01\SQL2019` - Remote server with named instance
  - `192.168.1.100` - IP address

**DB_NAME**: 
- The database name (default: `DMAP_JIT_Permissions`)

**DB_DRIVER**: 
- ODBC Driver version. Common options:
  - `{ODBC Driver 17 for SQL Server}` - Recommended (SQL Server 2012+)
  - `{ODBC Driver 13 for SQL Server}` - Older driver
  - `{SQL Server Native Client 11.0}` - Legacy
- To check available drivers: Run `odbcinst -q -d` on Linux/Mac, or check ODBC Data Source Administrator on Windows

**DB_USERNAME**: 
- Service account username for SQL Server Authentication
- This is the SQL Server login name (not Windows username)
- Example: `JIT_ServiceAccount`

**DB_PASSWORD**: 
- Service account password for SQL Server Authentication
- Store securely (use environment variables, not hardcoded)

**SECRET_KEY**: 
- Random string for Flask session security
- Generate with: `python -c "import secrets; print(secrets.token_hex(32))"`

### Connection String Format

The application uses **SQL Server Authentication** with a service account:
- Database connections use the service account credentials (`DB_USERNAME` / `DB_PASSWORD`)
- User identification uses Windows username (from environment variables or request headers)
- This separation allows centralized database access control while identifying end users

**Important**: The service account must have appropriate permissions on the `jit` schema (EXECUTE on procedures, SELECT/INSERT/UPDATE/DELETE on tables).

## 2. Service Account Setup

Before configuring the Flask application, you must create and configure the service account in SQL Server. See `SERVICE_ACCOUNT_SETUP.md` for detailed instructions.

Quick setup:
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

## 3. Authentication and Authorization Flow

### Authentication Process

1. **User Access**: User accesses the Flask application
2. **Windows Username Identification**: Flask gets Windows username from:
   - Environment variables (`USERNAME` or `USER`) in development
   - Request headers (`REMOTE_USER` or `AUTH_USER`) in production with IIS/Windows Auth
   
   **Testing Different Users in Development:**
   - Set the `USERNAME` environment variable before running Flask
   - Example (PowerShell): `$env:USERNAME = "DOMAIN\john.smith"`
   - Example (CMD): `set USERNAME=DOMAIN\john.smith`
   - See `DEVELOPMENT_TESTING_GUIDE.md` for detailed testing instructions
3. **Database Lookup**: Flask uses service account to query `jit.Users` table by `LoginName`
4. **User Validation**: User must exist in `jit.Users` table (no auto-creation)
5. **Session Storage**: User information is stored in Flask session with role flags
6. **Route Protection**: Decorators check user permissions before allowing access

### Authorization Levels

The framework uses three authorization levels:

#### 1. **Regular User** (`@login_required`)
- All authenticated users (exist in `jit.Users` table)
- **Navigation**: "My Access" section only
- **Can access**:
  - `/user/dashboard` - View their active grants
  - `/user/request` - Request new access
  - `/user/history` - View request history

#### 2. **Approver** (`@approver_required`)
- Users listed in `jit.Role_Approvers` table
- **Navigation**: "My Access" + "Approvals" sections
- **Can access**:
  - All user routes
  - `/approver/dashboard` - View pending approvals
  - `/approver/request/<id>` - Review request details
  - `/approver/approve/<id>` - Approve requests
  - `/approver/deny/<id>` - Deny requests

#### 3. **Admin** (`@admin_required`)
- Users with `IsAdmin = 1` in `jit.Users` table
- **Navigation**: "My Access" + "Approvals" + "Administration" sections
- **Can access**:
  - All user and approver routes
  - `/admin/dashboard` - Admin overview
  - `/admin/roles` - Manage roles
  - `/admin/teams` - Manage teams
  - `/admin/eligibility` - Manage eligibility rules
  - `/admin/users` - View/manage users
  - `/admin/reports` - View audit reports

## 4. How to Set Up Users

### Creating Users

**Important**: Users must be created manually or via AD sync before they can access the application. The framework does NOT auto-create users.

**Manual Creation**:
```sql
INSERT INTO jit.Users (LoginName, DisplayName, GivenName, Surname, Email, Department, Division, IsActive)
VALUES ('DOMAIN\username', 'Display Name', 'First', 'Last', 'user@domain.com', 'IT', 'Engineering', 1);
```

**AD Sync**: Use `sp_User_SyncFromAD` stored procedure with AD staging table

### Setting Up Approvers

To make a user an approver for a role:

```sql
INSERT INTO jit.Role_Approvers (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
FROM jit.Roles r
CROSS JOIN jit.Users u
WHERE r.RoleName = 'Full Database Access'
AND u.LoginName = 'DOMAIN\username';
```

### Setting Up Admins

To make a user an admin:

```sql
UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\adminuser';
```

## 5. Navigation and UI Access Control

The navigation menu in `base.html` shows different links based on user type:

- **Regular Users**: See "My Access" links (Dashboard, Request Access, History)
- **Approvers**: See "My Access" + "Approvals" links
- **Admins**: See "My Access" + "Approvals" + "Administration" links

The role flags (`IsApprover`, `IsAdmin`) are set in the Flask session and checked by templates.

## 5.5. Testing Database Connection

Before running the Flask application, you can test your database connection configuration:

```bash
cd flask_app
python test_db_connection.py
```

This script will:
- Validate your configuration settings
- Test the database connection
- Check if the `jit` schema and tables exist
- Verify database permissions
- Provide helpful error messages if something is wrong

**Example output (successful):**
```
============================================================
Database Connection Test
============================================================

Configuration:
  Server: localhost
  Database: DMAP_JIT_Permissions
  Driver: {ODBC Driver 17 for SQL Server}
  Username: JIT_ServiceAccount
  Password: ****************

Validating configuration...
  ✅ DB_SERVER: localhost
  ✅ DB_NAME: DMAP_JIT_Permissions
  ✅ DB_DRIVER: {ODBC Driver 17 for SQL Server}
  ✅ DB_USERNAME: JIT_ServiceAccount
  ✅ DB_PASSWORD: ****************

Testing database connection...
  ✅ Successfully connected to database!
  ✅ Query executed successfully
  ✅ jit schema exists
  ✅ jit.Users table exists
  ✅ SELECT permission on jit.Users: OK
```

## 6. Troubleshooting

### Connection Issues

**Error: "Login failed for user 'JIT_ServiceAccount'"**
- Check `DB_USERNAME` and `DB_PASSWORD` in `.env` file
- Verify the login exists: `SELECT * FROM sys.server_principals WHERE name = 'JIT_ServiceAccount'`
- Check password is correct

**Error: "Cannot open database 'DMAP_JIT_Permissions'"**
- Check `DB_NAME` is correct
- Verify database user exists: `SELECT * FROM sys.database_principals WHERE name = 'JIT_ServiceAccount'`
- Verify user has access to the database

**Error: "Driver not found"**
- Install ODBC Driver for SQL Server
- Update `DB_DRIVER` to match installed driver
- Check driver name in ODBC Data Source Administrator

### Authentication Issues

**Error: "User not found. Please contact your administrator to create your account."**
- User doesn't exist in `jit.Users` table
- Check Windows username format matches `LoginName` in database (e.g., `DOMAIN\username`)
- Create user manually or via AD sync

**User can't see admin/approver sections**
- Check `IsAdmin` flag: `SELECT LoginName, IsAdmin FROM jit.Users WHERE LoginName = 'DOMAIN\username'`
- Check approver status: `SELECT * FROM jit.Role_Approvers WHERE ApproverLoginName = 'DOMAIN\username'`
- Verify role flags are in session (check browser developer tools)
- Clear browser session/cookies and re-login

**Navigation doesn't show/hide links correctly**
- Check `session.user` contains `IsApprover` and `IsAdmin` flags
- Verify template checks: `session.user.get('IsApprover')` and `session.user.get('IsAdmin')`
- Check Flask logs for errors

### Service Account Permission Issues

**Error: "The EXECUTE permission was denied"**
- Grant execute permissions: `GRANT EXECUTE ON SCHEMA::jit TO [JIT_ServiceAccount];`

**Error: "The SELECT permission was denied"**
- Grant table permissions: `GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::jit TO [JIT_ServiceAccount];`

## 7. Production Deployment Considerations

- Use strong passwords for service account (follow organizational password policies)
- Store credentials securely (environment variables, key vaults, not hardcoded)
- Configure IIS with Windows Authentication for proper user identification in production
- Set `DEBUG=False` in production
- Use HTTPS for secure connections
- Regularly rotate service account passwords
- Monitor service account usage and permissions
- Review audit logs regularly
