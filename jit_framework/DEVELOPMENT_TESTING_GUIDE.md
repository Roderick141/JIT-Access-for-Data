# Development Testing Guide - User Login Testing

## Overview

In development, the Flask application uses the Windows `USERNAME` environment variable to identify users. This allows you to test different user accounts without needing to change your Windows login.

## How It Works

The authentication system (`utils/auth.py`) reads the `USERNAME` environment variable to identify the current user:

```python
windows_user = os.environ.get('USERNAME') or os.environ.get('USER')
```

This username is then used to look up the user in the `jit.Users` table by matching the `LoginName` column.

## Testing Different Users

### Method 1: Set Environment Variable Before Running Flask (Recommended)

You can set the `USERNAME` environment variable to test as different users. The application will look for this username (or `DOMAIN\username` format) in the `jit.Users` table.

#### On Windows (PowerShell):

```powershell
# Test as a specific user
$env:USERNAME = "DOMAIN\john.smith"
cd jit_framework\flask_app
python app.py
```

#### On Windows (Command Prompt):

```cmd
set USERNAME=DOMAIN\john.smith
cd jit_framework\flask_app
python app.py
```

#### Example: Test as Multiple Users

1. **Test as regular user:**
   ```powershell
   $env:USERNAME = "DOMAIN\john.smith"
   python app.py
   ```

2. **Test as approver:**
   ```powershell
   $env:USERNAME = "DOMAIN\approver1"
   python app.py
   ```

3. **Test as admin:**
   ```powershell
   $env:USERNAME = "DOMAIN\admin.user"
   python app.py
   ```

### Method 2: Create a Test Script

Create a simple batch file or PowerShell script to test different users:

**test_user.ps1:**
```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$Username
)

$env:USERNAME = $Username
Write-Host "Testing as: $env:USERNAME"
cd jit_framework\flask_app
python app.py
```

**Usage:**
```powershell
.\test_user.ps1 "DOMAIN\john.smith"
.\test_user.ps1 "DOMAIN\approver1"
.\test_user.ps1 "DOMAIN\admin.user"
```

### Method 3: Use Multiple Terminal Windows

1. Open multiple PowerShell/Command Prompt windows
2. In each window, set a different `USERNAME` environment variable
3. Run Flask in each window on different ports:

**Window 1 (Regular User):**
```powershell
$env:USERNAME = "DOMAIN\john.smith"
$env:FLASK_RUN_PORT = "5000"
cd jit_framework\flask_app
python app.py
```

**Window 2 (Approver):**
```powershell
$env:USERNAME = "DOMAIN\approver1"
$env:FLASK_RUN_PORT = "5001"
cd jit_framework\flask_app
python app.py
```

**Window 3 (Admin):**
```powershell
$env:USERNAME = "DOMAIN\admin.user"
$env:FLASK_RUN_PORT = "5002"
cd jit_framework\flask_app
python app.py
```

Then access:
- Regular user: http://localhost:5000
- Approver: http://localhost:5001
- Admin: http://localhost:5002

## Important Notes

### 1. User Must Exist in Database

**Critical:** The user must exist in the `jit.Users` table for authentication to work. The application does NOT auto-create users.

Before testing, ensure the user exists:
```sql
SELECT * FROM jit.Users WHERE LoginName = 'DOMAIN\john.smith';
```

If the user doesn't exist, create it:
```sql
INSERT INTO jit.Users (LoginName, DisplayName, GivenName, Surname, Email, IsActive)
VALUES ('DOMAIN\john.smith', 'John Smith', 'John', 'Smith', 'john.smith@company.com', 1);
```

### 2. Username Format

The username should match the `LoginName` format in the database:
- `DOMAIN\username` (recommended - matches Windows domain format)
- `username` (works if database has users without domain prefix)

### 3. Setting Admin/Approver Status

To test admin access:
```sql
UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\admin.user';
```

To test approver access, add user to Role_Approvers:
```sql
INSERT INTO jit.Role_Approvers (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
FROM jit.Roles r
CROSS JOIN jit.Users u
WHERE u.LoginName = 'DOMAIN\approver1'
AND r.RoleName = 'Advanced Analytics';  -- or any role
```

### 4. Environment Variable Scope

Environment variables set in PowerShell/CMD only affect that session:
- They persist until you close that terminal window
- They don't affect other terminal windows
- They don't persist after closing the terminal

To check current username:
```powershell
echo $env:USERNAME  # PowerShell
echo %USERNAME%     # CMD
```

## Quick Testing Checklist

1. ✅ User exists in `jit.Users` table
2. ✅ User has `IsActive = 1`
3. ✅ `LoginName` matches the format you're using (e.g., `DOMAIN\username`)
4. ✅ Set `USERNAME` environment variable before starting Flask
5. ✅ Flask app is running
6. ✅ Access http://localhost:5000 in browser

## Troubleshooting

### "User not found" Error

- Check if user exists: `SELECT * FROM jit.Users WHERE LoginName LIKE '%username%'`
- Verify `IsActive = 1`
- Check username format matches (domain prefix, case sensitivity)

### User Found But No Permissions

- Check `IsAdmin` flag: `SELECT LoginName, IsAdmin FROM jit.Users WHERE LoginName = 'DOMAIN\username'`
- Check approver status: `SELECT * FROM jit.Role_Approvers WHERE ApproverLoginName = 'DOMAIN\username'`

### Environment Variable Not Working

- Make sure you set it in the SAME terminal window where you run Flask
- Check the variable: `echo $env:USERNAME` (PowerShell) or `echo %USERNAME%` (CMD)
- Restart Flask after changing the environment variable

## Example Test Scenario

**Goal:** Test as three different users (regular user, approver, admin)

1. **Create test users in database:**
   ```sql
   -- Regular user
   INSERT INTO jit.Users (LoginName, DisplayName, IsActive)
   VALUES ('DOMAIN\testuser', 'Test User', 1);
   
   -- Approver
   INSERT INTO jit.Users (LoginName, DisplayName, IsActive)
   VALUES ('DOMAIN\testapprover', 'Test Approver', 1);
   
   INSERT INTO jit.Role_Approvers (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
   SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
   FROM jit.Roles r
   CROSS JOIN jit.Users u
   WHERE u.LoginName = 'DOMAIN\testapprover';
   
   -- Admin
   INSERT INTO jit.Users (LoginName, DisplayName, IsActive, IsAdmin)
   VALUES ('DOMAIN\testadmin', 'Test Admin', 1, 1);
   ```

2. **Test as regular user:**
   ```powershell
   $env:USERNAME = "DOMAIN\testuser"
   cd jit_framework\flask_app
   python app.py
   ```
   - Should see: "My Access" section only

3. **Test as approver:**
   ```powershell
   $env:USERNAME = "DOMAIN\testapprover"
   python app.py
   ```
   - Should see: "My Access" + "Approvals" sections

4. **Test as admin:**
   ```powershell
   $env:USERNAME = "DOMAIN\testadmin"
   python app.py
   ```
   - Should see: "My Access" + "Approvals" + "Administration" sections

