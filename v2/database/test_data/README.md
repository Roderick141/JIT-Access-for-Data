# Test Data Scripts

This directory contains SQL scripts to populate the JIT Access Framework database with test data for development and testing purposes.

## ⚠️ Important Warning

**These scripts should ONLY be used in test/development environments!** Do not run them in production databases.

## Quick Start

### Option 1: Run All Test Data (Recommended)

1. Enable SQLCMD mode in SQL Server Management Studio (Query > SQLCMD Mode)
2. Run `99_Insert_All_Test_Data.sql`

This will execute all test data scripts in the correct order.

### Option 2: Run Individual Scripts

Run each script in numerical order:
1. `01_Insert_Test_Users.sql` - Creates sample users
2. `02_Insert_Test_Roles.sql` - Creates business roles
3. `03_Insert_Test_DB_Roles.sql` - Creates database role metadata
4. `04_Insert_Test_Role_Mappings.sql` - Maps business roles to DB roles
5. `05_Insert_Test_Teams.sql` - Creates teams
6. `06_Insert_Test_User_Teams.sql` - Assigns users to teams
7. `07_Insert_Test_Eligibility_Rules.sql` - Creates eligibility rules
8. `09_Insert_Test_Requests.sql` - Creates sample requests (single and multi-role)
9. `09a_Insert_Test_Request_Roles.sql` - Associates roles with requests
10. `10_Insert_Test_Grants.sql` - Creates sample grants
11. `11_Insert_Test_Approvals.sql` - Creates approval records

## Test Data Overview

### Users Created

The test data includes users across multiple teams and departments:

- **Engineering Users:**
  - `DOMAIN\john.smith` - Principal Data Engineer (Level 4)
  - `DOMAIN\sarah.jones` - Director of Engineering (Level 5)
  - `DOMAIN\mike.wilson` - Senior Data Engineer (Level 3)
  - `DOMAIN\alex.taylor` - Junior Data Engineer (Level 1)

- **Business Users:**
  - `DOMAIN\emily.brown` - Senior Business Analyst (Level 3)
  - `DOMAIN\jessica.martin` - Business Analyst (Level 1)

- **Platform Users:**
  - `DOMAIN\david.lee` - DevOps Engineer

- **Approvers:**
  - `DOMAIN\approver1` - Data Manager
  - `DOMAIN\admin.user` - Security Administrator

### Roles Created

1. **Read-Only Reports** - Pre-approved, all users eligible
2. **Advanced Analytics** - Team-based eligibility, requires approval
3. **Data Warehouse Reader** - Department-based eligibility, requires approval
4. **Full Database Access** - Division-based eligibility, requires approval, requires ticket
5. **Data Administrator** - Team-based eligibility, requires approval, requires ticket
6. **Temporary Query Access** - Pre-approved, all users eligible, short duration

### Test Scenarios

The test data supports testing:

1. **Pre-approved Roles**: `Read-Only Reports` and `Temporary Query Access` are auto-approved
2. **Manual Approval**: `Advanced Analytics`, `Full Database Access`, and `Data Administrator` require manual approval
3. **Eligibility Rules**: Different scopes (All, Department, Division, Team)
4. **Expired Grants**: One grant is already expired for testing the expiry job
5. **Pending Requests**: Requests in various states (Pending, Approved, Denied, AutoApproved)

## Customization

### Changing User Domains

The scripts use `DOMAIN\` prefix for login names. To change this:

1. Search and replace `DOMAIN\` with your domain name in all scripts
2. Or update the INSERT statements to use your actual Windows login names

### Creating Database Roles

**Important:** Before running the test data, ensure these database roles exist in your database:

```sql
CREATE ROLE JIT_Reports_Reader;
CREATE ROLE JIT_Reports_Unmasked;
CREATE ROLE JIT_Analytics;

-- Grant appropriate permissions to these roles
-- Example:
-- GRANT SELECT ON SCHEMA::dbo TO JIT_Reports_Reader;
```

The standard SQL Server roles (`db_datareader`, `db_datawriter`) should already exist.

### Adjusting Test Data

You can modify any of the individual scripts to:
- Change user details
- Add more users/roles/teams
- Adjust eligibility rules
- Modify approval requirements

## Verification Queries

After inserting test data, you can verify with these queries:

```sql
-- Count records in each table
SELECT 'Users' AS TableName, COUNT(*) AS RecordCount FROM jit.Users
UNION ALL
SELECT 'Roles', COUNT(*) FROM jit.Roles
UNION ALL
SELECT 'Teams', COUNT(*) FROM jit.Teams
UNION ALL
SELECT 'Requests', COUNT(*) FROM jit.Requests
UNION ALL
SELECT 'Grants', COUNT(*) FROM jit.Grants;

-- View active grants
SELECT u.LoginName, r.RoleName, g.ValidFromUtc, g.ValidToUtc, g.Status
FROM jit.Grants g
INNER JOIN jit.Users u ON g.UserId = u.UserId
INNER JOIN jit.Roles r ON g.RoleId = r.RoleId
WHERE g.Status = 'Active';

-- View pending requests
SELECT u.LoginName, r.RoleName, req.Status, req.CreatedUtc
FROM jit.Requests req
INNER JOIN jit.Users u ON req.UserId = u.UserId
INNER JOIN jit.Roles r ON req.RoleId = r.RoleId
WHERE req.Status = 'Pending';
```

## Troubleshooting

### Foreign Key Violations

If you get foreign key violations, ensure you're running scripts in the correct order as listed above.

### Duplicate Key Violations

If you get duplicate key errors, the data may already exist. You can either:
1. Clear existing data first (see comments in `99_Insert_All_Test_Data.sql`)
2. Modify the scripts to use `MERGE` or check for existence before inserting

### Database Roles Don't Exist

If you get errors about database roles not existing:
1. Create the required roles first (see "Creating Database Roles" above)
2. Or modify `03_Insert_Test_DB_Roles.sql` to use roles that exist in your database

