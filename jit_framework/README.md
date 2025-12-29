# JIT Access Framework

Just-In-Time Access Framework for SQL Server Database Access Control

## Overview

This framework provides a comprehensive solution for managing temporary, time-bound access to SQL Server database resources through a role-based access control system with automatic expiration and approval workflows.

## Features

- **Identity Management**: Windows Authentication integration with AD enrichment
- **Role-Based Access**: Requestable business roles mapped to database roles
- **Multi-Scope Eligibility**: Support for user, department, division, team, and global eligibility rules
- **Auto-Approval**: Pre-approved roles and seniority-based auto-approval
- **Approval Workflow**: Manual approval for sensitive roles
- **Automatic Expiration**: SQL Agent jobs automatically revoke expired access
- **Comprehensive Audit**: Complete audit trail of all access grants and changes
- **Flask Web Interface**: Dark mode web application for user requests, approvals, and administration

## Directory Structure

```
jit_framework/
├── database/
│   ├── schema/          # Database table creation scripts
│   ├── procedures/      # Stored procedures
│   └── jobs/           # SQL Agent job scripts
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
- Windows Authentication enabled on SQL Server
- ODBC Driver for SQL Server

### Database Setup

1. Create the database (if not exists):
   ```sql
   CREATE DATABASE [DMAP_JIT_Permissions]
   ```

2. Run schema creation scripts in order:
   - `database/schema/00_Create_jit_Schema.sql`
   - `database/schema/01_Create_Users.sql` through `14_Create_AuditLog.sql`

3. Create stored procedures from `database/procedures/` directory

4. Create SQL Agent jobs from `database/jobs/` directory

### Flask Application Setup

1. Install Python dependencies:
   ```bash
   cd flask_app
   pip install -r requirements.txt
   ```

2. Configure environment variables (create `.env` file):
   ```
   DB_SERVER=your_sql_server
   DB_NAME=DMAP_JIT_Permissions
   DB_DRIVER={ODBC Driver 17 for SQL Server}
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

### Approver Portal

- View pending approval requests
- Approve or deny requests with comments
- Review requester details and justification

### Admin Portal

- Manage role catalog
- Configure teams and eligibility rules
- View audit reports
- Manage users

## Security Considerations

- All database operations use Windows Authentication
- Only whitelisted roles can be managed by the framework
- Direct grants to users are monitored and reported
- Complete audit trail of all operations
- Automatic expiration of access grants
- Reconciliation jobs detect and report drift

## Notes

- The framework assumes Windows Authentication for both SQL Server and the Flask application
- AD sync must be configured separately (PowerShell script recommended)
- SQL Agent jobs must be configured for automatic expiration
- Review and configure security permissions for the `jit` schema

## License

[Your License Here]

