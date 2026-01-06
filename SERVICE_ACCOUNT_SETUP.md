# Service Account Setup Guide

## Overview

The Flask application now uses a **service account** for database connections instead of Windows Authentication. This means:

1. **Database Connection**: Uses SQL Server Authentication with service account credentials
2. **User Identification**: Still identifies users by their Windows username (from environment/request headers)
3. **No Auto-User Creation**: Users must exist in the database before they can access the application

## Setting Up the Service Account

### Step 1: Create SQL Server Login

In SQL Server Management Studio, run:

```sql
-- Create the login
CREATE LOGIN [JIT_ServiceAccount] WITH PASSWORD = 'YourStrongPasswordHere123!';
```

### Step 2: Create Database User

```sql
USE [DMAP_JIT_Permissions];
GO

-- Create the database user
CREATE USER [JIT_ServiceAccount] FOR LOGIN [JIT_ServiceAccount];
GO
```

### Step 3: Grant Permissions

```sql
-- Grant execute permissions on all stored procedures in jit schema
GRANT EXECUTE ON SCHEMA::jit TO [JIT_ServiceAccount];

-- Grant SELECT, INSERT, UPDATE, DELETE on all tables in jit schema
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::jit TO [JIT_ServiceAccount];

-- Optional: Grant VIEW DEFINITION if you want the service account to see schema structure
GRANT VIEW DEFINITION ON SCHEMA::jit TO [JIT_ServiceAccount];
```

### Step 4: Configure Flask Application

Update your `.env` file in `flask_app/` directory:

```env
DB_SERVER=your_server_name
DB_NAME=DMAP_JIT_Permissions
DB_DRIVER={ODBC Driver 17 for SQL Server}
DB_USERNAME=JIT_ServiceAccount
DB_PASSWORD=YourStrongPasswordHere123!
SECRET_KEY=your-secret-key-here
```

## How User Identification Works

Even though the database connection uses a service account, the application still identifies users by their Windows username:

1. **Development**: Gets Windows username from environment variables (`USERNAME` or `USER`)
2. **Production (IIS)**: Gets Windows username from request headers (`REMOTE_USER` or `AUTH_USER`)
3. **Database Lookup**: Uses the service account connection to query `jit.Users` table by `LoginName`

**Important**: The Windows username is only used for identification. The actual database queries all use the service account credentials.

## Setting Up Admin Users

After adding the `IsAdmin` column to the Users table, set users as administrators:

```sql
-- Add IsAdmin column (if not already added)
ALTER TABLE jit.Users ADD IsAdmin BIT NOT NULL DEFAULT 0;
GO

-- Set a user as admin
UPDATE jit.Users 
SET IsAdmin = 1 
WHERE LoginName = 'DOMAIN\adminusername';
```

## Setting Up Approvers

Approvers are users listed in the `jit.Role_Approvers` table:

```sql
-- Add user as approver for a specific role
INSERT INTO jit.Role_Approvers (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
FROM jit.Roles r
CROSS JOIN jit.Users u
WHERE r.RoleName = 'Full Database Access'
AND u.LoginName = 'DOMAIN\approverusername';
```

## Migration Notes

### For Existing Installations

1. **Run the ALTER script** to add `IsAdmin` column:
   ```sql
   :r "database/schema/01_ALTER_Users_Add_IsAdmin.sql"
   ```

2. **Update stored procedures** (recreate them):
   ```sql
   :r "database/procedures/99_Create_All_Procedures.sql"
   ```

3. **Update environment variables** in `.env` file

4. **Create and configure service account** (see steps above)

5. **Set admin users** (see "Setting Up Admin Users" above)

### Important Notes

- **No Auto-User Creation**: Users must be created manually or via AD sync before they can access the application
- **Stored Procedure Limitation**: `sp_User_ResolveCurrentUser` uses `ORIGINAL_LOGIN()`, which will return the service account name. The Flask app doesn't use this procedure - it queries directly using the Windows username from the environment/headers.
- **Security**: Store service account credentials securely (environment variables, not hardcoded)
- **Password Policy**: Use strong passwords for the service account and follow your organization's password policies

## Troubleshooting

### Connection Errors

**Error: "Login failed for user 'JIT_ServiceAccount'"**
- Check the username and password in `.env` file
- Verify the login exists in SQL Server: `SELECT * FROM sys.server_principals WHERE name = 'JIT_ServiceAccount'`

**Error: "Cannot open database 'DMAP_JIT_Permissions'"**
- Verify the database user exists: `SELECT * FROM sys.database_principals WHERE name = 'JIT_ServiceAccount'`
- Check that the user has access to the database

**Error: "The SELECT permission was denied"**
- Verify permissions were granted: `SELECT * FROM sys.database_permissions WHERE grantee_principal_id = USER_ID('JIT_ServiceAccount')`
- Re-run the GRANT statements from Step 3

### User Not Found

**Error: "User not found. Please contact your administrator to create your account."**
- User doesn't exist in `jit.Users` table
- Create user manually or run AD sync
- Check Windows username format matches the `LoginName` in database (e.g., `DOMAIN\username`)

### Admin/Approver Access Issues

**User can't see Admin/Approver sections**
- Check `IsAdmin` flag: `SELECT LoginName, IsAdmin FROM jit.Users WHERE LoginName = 'DOMAIN\username'`
- Check approver status: `SELECT * FROM jit.Role_Approvers WHERE ApproverLoginName = 'DOMAIN\username'`
- Verify role flags are set in session (check browser developer tools, session data)

