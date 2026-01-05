# Changes Summary - Service Account & Admin Role Implementation

## Changes Made

### 1. Removed Auto-User Creation
- **File**: `database/procedures/sp_User_ResolveCurrentUser.sql`
- **Change**: Removed the logic that automatically creates user records
- **Impact**: Users must now be created manually or via AD sync before they can access the system
- **Behavior**: If user doesn't exist, procedure returns NULL values instead of creating a record

### 2. Added IsAdmin Column
- **File**: `database/schema/01_Create_Users.sql` (updated schema)
- **Change**: Added `IsAdmin BIT NOT NULL DEFAULT 0` column to Users table
- **Impact**: Enables proper admin role checking
- **Note**: For fresh deployments, the column is included in the CREATE script. For existing deployments, users should redeploy or manually add the column.

### 3. Changed Database Connection to Service Account
- **File**: `flask_app/config.py`
- **Change**: Switched from Windows Authentication (Trusted_Connection) to SQL Server Authentication
- **New Environment Variables**:
  - `DB_USERNAME` - Service account username
  - `DB_PASSWORD` - Service account password
- **Removed**: `DB_TRUSTED_CONNECTION`
- **Impact**: All database connections now use the service account credentials

### 4. Updated Authentication Logic
- **File**: `flask_app/utils/auth.py`
- **Changes**:
  - Removed auto-user creation logic
  - Implemented proper `is_admin()` function that checks `IsAdmin` column
  - Improved `get_current_user()` to not create users
  - Better error handling when user doesn't exist
- **Impact**: Users must exist in database, proper admin checking works

### 5. Updated Navigation and Templates
- **Files**: 
  - `flask_app/templates/base.html`
  - `flask_app/templates/user/dashboard.html`
  - `flask_app/templates/approver/dashboard.html`
  - `flask_app/templates/admin/dashboard.html`
- **Changes**:
  - Clear navigation structure: "My Access", "Approvals", "Administration"
  - Added navigation menus to each section
  - Proper role-based visibility (users see user pages, approvers see user+approver, admins see all)
- **Impact**: Better UX with clear navigation and proper access control

### 6. Updated Stored Procedures
- **Files**:
  - `database/procedures/sp_User_GetByLogin.sql` - Added IsAdmin to SELECT
  - `database/procedures/sp_User_ResolveCurrentUser.sql` - Added IsAdmin OUTPUT parameter, removed auto-create
  - `database/procedures/sp_User_SyncFromAD.sql` - Added IsAdmin to INSERT (defaults to 0)

## Configuration Changes Required

### 1. Database Schema
For fresh deployments, the `IsAdmin` column is included in `01_Create_Users.sql`. No migration script is needed.

For existing deployments, you can either:
- Redeploy the schema (drop and recreate tables)
- Manually add the column: `ALTER TABLE jit.Users ADD IsAdmin BIT NOT NULL DEFAULT 0;`

### 2. Environment Variables Update
Update your `.env` file:
```env
# OLD (Windows Auth):
# DB_TRUSTED_CONNECTION=yes

# NEW (SQL Server Auth with Service Account):
DB_USERNAME=your_service_account_username
DB_PASSWORD=your_service_account_password
```

### 3. Create Service Account in SQL Server
1. In SQL Server Management Studio, create a SQL Server login:
   ```sql
   CREATE LOGIN [JIT_ServiceAccount] WITH PASSWORD = 'StrongPasswordHere';
   ```

2. Grant access to the database:
   ```sql
   USE [DMAP_JIT_Permissions];
   CREATE USER [JIT_ServiceAccount] FOR LOGIN [JIT_ServiceAccount];
   ```

3. Grant necessary permissions:
   ```sql
   -- Grant execute permissions on jit schema procedures
   GRANT EXECUTE ON SCHEMA::jit TO [JIT_ServiceAccount];
   
   -- Grant SELECT, INSERT, UPDATE, DELETE on jit schema tables
   GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::jit TO [JIT_ServiceAccount];
   ```

### 4. Set Up Admin Users
After adding the IsAdmin column, set users as admins:
```sql
UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\adminuser';
```

## User Access Levels

### Regular User
- **Navigation**: "My Access" section only
- **Pages**: Dashboard, Request Access, History
- **Determined by**: User exists in jit.Users table

### Approver
- **Navigation**: "My Access" + "Approvals" sections
- **Pages**: All user pages + Approver dashboard, Review requests
- **Determined by**: User's UserId exists in jit.Role_Approvers table

### Admin
- **Navigation**: "My Access" + "Approvals" + "Administration" sections
- **Pages**: All pages including admin management
- **Determined by**: User has IsAdmin = 1 in jit.Users table

## Important Notes

1. **User Creation**: Users must now be created manually or via AD sync before they can log in
2. **Service Account**: Ensure the service account has appropriate permissions
3. **Security**: Store service account credentials securely (use environment variables, not hardcoded)
4. **Windows User Identification**: The app still uses Windows username for identifying users, but database connection uses service account
5. **Migration**: Existing installations need to run the ALTER script to add IsAdmin column

