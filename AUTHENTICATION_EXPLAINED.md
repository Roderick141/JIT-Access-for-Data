# Authentication and Authorization Explained

## Quick Summary

This document explains how database connection and user authentication/authorization works in the JIT Access Framework Flask application.

**Key Points**:
- Database connections use **SQL Server Authentication** with a service account
- User identification uses **Windows username** (from environment/request headers)
- Users must exist in database (no auto-creation)
- Three access levels: User, Approver, Admin

---

## Part 1: Database Connection Setup

### Configuration File Location
Create a `.env` file in the `flask_app` directory (see `.env.example` for template)

### Required Settings

```env
DB_SERVER=your_sql_server_name
DB_NAME=DMAP_JIT_Permissions
DB_DRIVER={ODBC Driver 17 for SQL Server}
DB_USERNAME=JIT_ServiceAccount
DB_PASSWORD=your_service_account_password
```

**Key Points:**
- `DB_SERVER`: Your SQL Server instance (e.g., `localhost`, `SERVER01\SQL2019`)
- `DB_USERNAME` / `DB_PASSWORD`: Service account credentials for SQL Server Authentication
- All database connections use the service account credentials
- User identification is separate (uses Windows username)

---

## Part 2: How User Authentication Works

### Step-by-Step Flow

1. **User Accesses Flask App**
   - User opens browser and navigates to Flask application URL

2. **Windows Username Identification**
   - Flask gets Windows username from:
     - Environment variables (`USERNAME` or `USER`) in development
     - Request headers (`REMOTE_USER` or `AUTH_USER`) in production with IIS/Windows Auth
   - This is used for user identification only, not database connection

3. **Database Connection**
   - Flask uses service account credentials (`DB_USERNAME` / `DB_PASSWORD`) to connect to SQL Server
   - All database queries use this service account connection

4. **User Resolution in Database**
   - Flask queries `jit.Users` table using the Windows username as `LoginName`
   - User must exist in the database (no auto-creation)
   - If user not found, access is denied with message "User not found. Please contact your administrator."

5. **Session Storage**
   - User information stored in Flask session
   - Session persists across page requests
   - Includes: UserId, LoginName, DisplayName, IsAdmin, IsApprover flags, etc.

6. **Route Access Control**
   - Decorators (`@login_required`, `@approver_required`, `@admin_required`) check permissions
   - User redirected to login if not authenticated
   - User redirected to dashboard with error message if lacks required permissions

---

## Part 3: User Types and What They Can See

### Regular User (All Authenticated Users)

**Navigation Shows:**
- My Access → Dashboard, Request Access, History

**Can Access:**
- `/user/dashboard` - View their active grants
- `/user/request` - Request new access to roles
- `/user/history` - View all their requests
- `/user/cancel/<id>` - Cancel pending requests

**How Determined:**
- User exists in `jit.Users` table with `IsActive = 1`
- User is authenticated (Windows username found in database)

---

### Approver User

**Navigation Shows:**
- My Access → Dashboard, Request Access, History
- Approvals → Pending Approvals

**Can Access:**
- All regular user routes
- `/approver/dashboard` - View pending approval requests
- `/approver/request/<id>` - Review request details
- `/approver/approve/<id>` - Approve requests
- `/approver/deny/<id>` - Deny requests

**How Determined:**
- User's `UserId` is found in `jit.Role_Approvers` table
- Checked by `is_approver(user_id)` function
- Navigation shows "Approvals" link if `IsApprover = True` in session

**To Make a User an Approver:**
```sql
INSERT INTO jit.Role_Approvers (RoleId, ApproverUserId, ApproverLoginName, ApproverType, Priority)
SELECT r.RoleId, u.UserId, u.LoginName, 'User', 1
FROM jit.Roles r
CROSS JOIN jit.Users u
WHERE r.RoleName = 'Full Database Access'
AND u.LoginName = 'DOMAIN\username';
```

---

### Admin User

**Navigation Shows:**
- My Access → Dashboard, Request Access, History
- Approvals → Pending Approvals (if also approver)
- Administration → Overview, Roles, Teams, Eligibility, Users, Reports

**Can Access:**
- All user and approver routes
- `/admin/dashboard` - Admin overview
- `/admin/roles` - Manage role catalog
- `/admin/teams` - Manage teams
- `/admin/eligibility` - Manage eligibility rules
- `/admin/users` - View/manage users
- `/admin/reports` - View audit reports

**How Determined:**
- User has `IsAdmin = 1` in `jit.Users` table
- Checked by `is_admin(user_id)` function
- Navigation shows "Administration" link if `IsAdmin = True` in session

**To Make a User an Admin:**
```sql
UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\adminuser';
```

---

## Part 4: How Navigation Menu Works

The navigation menu in `templates/base.html` checks user flags in the session:

```html
<!-- User section - all authenticated users see this -->
<li><a href="{{ url_for('user_dashboard') }}">My Access</a></li>

<!-- Approver section - only if IsApprover = True -->
{% if session.user.get('IsApprover') %}
    <li><a href="{{ url_for('approver_dashboard') }}">Approvals</a></li>
{% endif %}

<!-- Admin section - only if IsAdmin = True -->
{% if session.user.get('IsAdmin') %}
    <li><a href="{{ url_for('admin_dashboard') }}">Administration</a></li>
{% endif %}
```

**Important:** These flags (`IsApprover`, `IsAdmin`) are added to the user session in `app.py`:

```python
user['IsApprover'] = is_approver(user.get('UserId'))
user['IsAdmin'] = is_admin(user.get('UserId'))
session['user'] = user
```

---

## Part 5: Route Protection

Routes are protected with decorators:

```python
@app.route('/user/dashboard')
@login_required  # Must be authenticated (user exists in database)
def user_dashboard():
    ...

@app.route('/approver/dashboard')
@approver_required  # Must be authenticated AND be an approver
def approver_dashboard():
    ...

@app.route('/admin/dashboard')
@admin_required  # Must be authenticated AND be an admin
def admin_dashboard():
    ...
```

**What Happens:**
- `@login_required`: Checks if user exists in database, redirects to `/login` if not
- `@approver_required`: Checks if user is approver, redirects to dashboard with error if not
- `@admin_required`: Checks if user is admin, redirects to dashboard with error if not

---

## Part 6: User Creation (No Auto-Creation)

**Important**: Users must be created manually or via AD sync before they can access the application.

### Manual Creation
```sql
INSERT INTO jit.Users (LoginName, DisplayName, GivenName, Surname, Email, Department, Division, IsActive, IsAdmin)
VALUES ('DOMAIN\username', 'Display Name', 'First', 'Last', 'user@domain.com', 'IT', 'Engineering', 1, 0);
```

### AD Sync
Use the `sp_User_SyncFromAD` stored procedure with an AD staging table to bulk import users.

### After Creation
- User can immediately access the application (regular user access)
- Set `IsAdmin = 1` to grant admin access
- Add to `jit.Role_Approvers` table to grant approver access

---

## Part 7: Testing Your Setup

### Test as Regular User
1. Ensure user exists in `jit.Users` table
2. Login with that user
3. Should see: "My Access" section only (Dashboard, Request Access, History)
4. Can request access, view history

### Test as Approver
1. Add user to `Role_Approvers` table (see SQL above)
2. Login with that user
3. Should see: "My Access" + "Approvals" sections
4. Can approve/deny requests

### Test as Admin
1. Set `IsAdmin = 1` for user: `UPDATE jit.Users SET IsAdmin = 1 WHERE LoginName = 'DOMAIN\username';`
2. Login with that user
3. Should see: "My Access" + "Approvals" + "Administration" sections
4. Can access all admin functions

---

## Part 8: Troubleshooting

**Q: User can't login - "User not found"**
- Check Windows account format matches `LoginName` in database (e.g., `DOMAIN\username`)
- Check user exists in `jit.Users` table: `SELECT * FROM jit.Users WHERE LoginName = 'DOMAIN\username'`
- Check `IsActive = 1`: `SELECT * FROM jit.Users WHERE LoginName = 'DOMAIN\username' AND IsActive = 1`
- Create user manually or via AD sync

**Q: User can see Approvals/Admin links but gets "permission denied"**
- Check user is actually in `Role_Approvers` table (for approver): `SELECT * FROM jit.Role_Approvers WHERE ApproverLoginName = 'DOMAIN\username'`
- Check user has `IsAdmin = 1` (for admin): `SELECT LoginName, IsAdmin FROM jit.Users WHERE LoginName = 'DOMAIN\username'`
- Check decorators are working (check Flask logs for errors)
- Clear browser session/cookies and re-login

**Q: Navigation doesn't show/hide links correctly**
- Check `session.user` contains `IsApprover` and `IsAdmin` flags (check browser developer tools)
- Check template is using `session.user.get('IsApprover')` syntax correctly
- Verify role flags are set in `app.py` login/index routes
- Clear browser session/cookies and re-login

**Q: Database connection errors**
- Check service account credentials in `.env` file (`DB_USERNAME`, `DB_PASSWORD`)
- Verify service account login exists: `SELECT * FROM sys.server_principals WHERE name = 'JIT_ServiceAccount'`
- Verify service account has permissions: `SELECT * FROM sys.database_permissions WHERE grantee_principal_id = USER_ID('JIT_ServiceAccount')`
- See `SERVICE_ACCOUNT_SETUP.md` for detailed setup instructions

---

## Summary

- **Database Connection**: SQL Server Authentication with service account (`DB_USERNAME` / `DB_PASSWORD`)
- **User Identification**: Windows username (from environment/request headers)
- **User Creation**: Manual or via AD sync (no auto-creation)
- **Access Levels**: User (default), Approver (in `Role_Approvers`), Admin (`IsAdmin = 1`)
- **Navigation**: Shows sections based on user's role flags in session
- **Security**: Service account has limited permissions, users identified separately
