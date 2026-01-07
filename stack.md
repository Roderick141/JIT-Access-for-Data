# Technology Stack

## Backend

### Database
- **SQL Server 2016+** (T-SQL)
- **Stored Procedures**: Business logic in database
- **Tables**: 15 tables in `jit` schema
- **SQL Agent Jobs**: Automated expiration and reconciliation
- **Indexes**: Optimized for frequent queries (Division, SeniorityLevel, Status, etc.)

### Database Access
- **Authentication**: SQL Server Authentication (service account)
- **Connection Library**: pyodbc (ODBC Driver for SQL Server)
- **Connection Pooling**: Per-request connections via Flask

## Frontend

### Web Framework
- **Flask 3.0+**: Python web framework
- **Templating**: Jinja2
- **Session Management**: Flask sessions (server-side)

### Styling
- **HTML5**: Semantic markup
- **CSS3**: Custom dark mode stylesheet
- **Responsive Design**: Mobile-friendly layouts

### JavaScript
- **Vanilla JavaScript**: No frameworks (minimal dependencies)
- **Form Validation**: Dynamic validation based on selected roles
- **UI Enhancements**: Multi-select role selection with real-time updates

## Authentication & Authorization

### Database Connection
- **Method**: SQL Server Authentication (UID/PWD)
- **Account**: Service account (`JIT_ServiceAccount`)
- **Permissions**: EXECUTE on schema, SELECT/INSERT/UPDATE/DELETE on tables

### User Identification
- **Method**: Windows username
- **Development**: Environment variables (`USERNAME`, `USER`)
- **Production**: Request headers (`REMOTE_USER`, `AUTH_USER`) with IIS/Windows Auth
- **Storage**: Flask session

### Authorization Levels
- **User**: Default access (view grants, request access)
- **Approver**: Can approve requests (division + seniority based)
- **Admin**: Full access (`IsAdmin = 1` flag)

## Configuration

### Environment Variables
- **DB_SERVER**: SQL Server instance
- **DB_NAME**: Database name
- **DB_DRIVER**: ODBC driver
- **DB_USERNAME**: Service account username
- **DB_PASSWORD**: Service account password
- **SECRET_KEY**: Flask session secret

### Configuration Files
- **`.env`**: Environment variables (not committed to git)
- **`config.py`**: Flask configuration loader

## Dependencies

### Python Packages
```
Flask>=3.0.0
pyodbc>=5.0.0
python-dotenv>=1.0.0
```

## Deployment

### Database
- **Scripts**: SQLCMD-compatible SQL scripts
- **Master Scripts**: `99_Create_All_Tables.sql`, `99_Create_All_Procedures.sql`
- **Deployment**: `01_Deploy_Everything.sql`
- **Cleanup**: `02_Cleanup_Everything.sql`

### Application
- **Server**: Development server (`python app.py`) or production WSGI server
- **Production**: IIS with FastCGI or standalone WSGI server (Gunicorn, uWSGI)

