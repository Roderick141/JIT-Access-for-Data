# IIS Setup Guide for Flask with Windows Authentication

This guide walks you through configuring IIS to run your Flask application with Windows Authentication, ensuring that Windows user credentials are passed through to Flask via HTTP headers.

## Prerequisites

- Windows Server with IIS installed
- Python installed on the server
- Flask application ready to deploy
- IIS URL Rewrite module installed
- Application Request Routing (ARR) module installed (optional, for reverse proxy)

## Step 1: Install Required IIS Modules

### Install IIS URL Rewrite Module
1. Download from: https://www.iis.net/downloads/microsoft/url-rewrite
2. Install the module
3. Verify installation: Open IIS Manager → Server → Modules → Look for "Rewrite"

### Install Application Request Routing (ARR) - Optional but Recommended
1. Download from: https://www.iis.net/downloads/microsoft/application-request-routing
2. Install the module
3. Enable Proxy: IIS Manager → Server → Application Request Routing Cache → Server Proxy Settings → Check "Enable proxy"

## Step 2: Install Python and Flask Dependencies

1. Install Python (3.8 or higher recommended)
2. Create a virtual environment:
   ```powershell
   cd C:\inetpub\wwwroot\your-flask-app
   python -m venv venv
   venv\Scripts\activate
   pip install flask pyodbc python-dotenv
   ```

3. Install `wfastcgi` (Windows FastCGI handler for Python):
   ```powershell
   pip install wfastcgi
   ```

## Step 3: Configure Your Flask Application

### Update `flask_app/utils/auth.py`

Modify the `get_windows_username()` function to read from IIS headers:

```python
def get_windows_username():
    """
    Get the current Windows username from IIS headers
    """
    # Priority order: REMOTE_USER is standard, AUTH_USER is IIS-specific
    windows_user = (
        request.headers.get('REMOTE_USER') or 
        request.headers.get('AUTH_USER') or 
        request.headers.get('LOGON_USER') or
        request.headers.get('HTTP_X_FORWARDED_USER') or
        request.headers.get('HTTP_X_REMOTE_USER') or
        None
    )
    
    # Fallback to environment for development
    if not windows_user:
        windows_user = os.environ.get('USERNAME') or os.environ.get('USER') or None
    
    return windows_user
```

## Step 4: Create web.config for IIS

Create a `web.config` file in your Flask application root directory:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <!-- Enable Windows Authentication -->
    <security>
      <authentication>
        <anonymousAuthentication enabled="false" />
        <windowsAuthentication enabled="true" />
      </authentication>
    </security>
    
    <!-- URL Rewrite Rules -->
    <rewrite>
      <rules>
        <rule name="Flask FastCGI" stopProcessing="true">
          <match url="(.*)" ignoreCase="false" />
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
          </conditions>
          <action type="Rewrite" url="handler.fcgi/{R:1}" appendQueryString="true" />
        </rule>
      </rules>
    </rewrite>
    
    <!-- HTTP Headers - Pass Windows Auth to Flask -->
    <httpProtocol>
      <customHeaders>
        <!-- IIS will automatically set REMOTE_USER when Windows Auth is enabled -->
      </customHeaders>
    </httpProtocol>
    
    <!-- Handler Mappings -->
    <handlers>
      <add name="Flask FastCGI" path="handler.fcgi" verb="*" modules="FastCgiModule" 
           scriptProcessor="C:\Python312\python.exe|C:\Python312\Lib\site-packages\wfastcgi.py" 
           resourceType="Unspecified" requireAccess="Script" />
    </handlers>
    
    <!-- FastCGI Settings -->
    <fastCgi>
      <application fullPath="C:\Python312\python.exe" 
                  arguments="C:\Python312\Lib\site-packages\wfastcgi.py" 
                  maxInstances="4" 
                  idleTimeout="1800" 
                  activityTimeout="30" 
                  requestTimeout="90" 
                  instanceMaxRequests="10000" 
                  protocol="NamedPipe" 
                  flushNamedPipe="False">
        <environmentVariables>
          <environmentVariable name="WSGI_HANDLER" value="app.app" />
          <environmentVariable name="PYTHONPATH" value="C:\inetpub\wwwroot\your-flask-app" />
          <!-- Add your database connection strings here -->
          <environmentVariable name="DB_SERVER" value="your-sql-server" />
          <environmentVariable name="DB_NAME" value="your-database" />
          <environmentVariable name="DB_USERNAME" value="your-service-account" />
          <environmentVariable name="DB_PASSWORD" value="your-password" />
          <environmentVariable name="SECRET_KEY" value="your-secret-key" />
        </environmentVariables>
      </application>
    </fastCgi>
  </system.webServer>
</configuration>
```

**Important:** Update the paths in `web.config`:
- `C:\Python312\python.exe` → Your Python executable path
- `C:\Python312\Lib\site-packages\wfastcgi.py` → Your wfastcgi.py path
- `C:\inetpub\wwwroot\your-flask-app` → Your Flask app directory
- Update environment variables with your actual values

## Step 5: Enable FastCGI in IIS

1. Open IIS Manager
2. Select your server in the left panel
3. Double-click "FastCGI Settings"
4. Click "Add Application" in the right panel
5. Set:
   - **Full Path**: `C:\Python312\python.exe` (your Python path)
   - **Arguments**: `C:\Python312\Lib\site-packages\wfastcgi.py`
   - **Instance MaxRequests**: `10000`
   - **Max Instances**: `4`
   - **Idle Timeout**: `1800`
   - **Activity Timeout**: `30`
   - **Request Timeout**: `90`
6. Click "Environment Variables" → Add:
   - `WSGI_HANDLER` = `app.app`
   - `PYTHONPATH` = `C:\inetpub\wwwroot\your-flask-app`
   - Add your database connection variables

## Step 6: Create IIS Application

1. Open IIS Manager
2. Right-click "Sites" → "Add Website"
3. Configure:
   - **Site name**: `JIT-Access-App` (or your preferred name)
   - **Application pool**: Create new or use existing
   - **Physical path**: `C:\inetpub\wwwroot\your-flask-app\flask_app`
   - **Binding**: 
     - Type: `http` or `https`
     - IP address: `All Unassigned` or specific IP
     - Port: `80` (or `443` for HTTPS)
     - Host name: `your-domain.com` (optional)
4. Click "OK"

## Step 7: Configure Application Pool

1. In IIS Manager, select "Application Pools"
2. Select your application pool
3. Click "Advanced Settings"
4. Configure:
   - **.NET CLR Version**: `No Managed Code`
   - **Managed Pipeline Mode**: `Integrated`
   - **Identity**: `ApplicationPoolIdentity` (or specific service account)
   - **Load User Profile**: `True` (important for Python)
5. Click "OK"

## Step 8: Enable Windows Authentication

1. Select your website in IIS Manager
2. Double-click "Authentication"
3. Right-click "Anonymous Authentication" → "Disable"
4. Right-click "Windows Authentication" → "Enable"
5. Right-click "Windows Authentication" → "Advanced Settings"
6. Configure:
   - **Extended Protection**: `Off` (or `Accept` if your environment supports it)
   - **Enable Kernel-mode authentication**: `True` (recommended for performance)

## Step 9: Configure Provider Settings (Optional)

1. Select "Windows Authentication" → "Providers"
2. Ensure providers are in this order:
   - `Negotiate` (first)
   - `NTLM` (second)

## Step 10: Set Permissions

### File System Permissions
1. Right-click your Flask app folder → "Properties" → "Security"
2. Add permissions for:
   - `IIS_IUSRS`: Read & Execute
   - `IIS AppPool\YourAppPoolName`: Read & Execute
   - Your service account (if using): Read & Execute

### IIS Manager Permissions
1. Select your website → "Edit Permissions" → "Security"
2. Ensure `IIS_IUSRS` has appropriate permissions

## Step 11: Create handler.fcgi File

Create a file named `handler.fcgi` in your Flask app directory (same level as `app.py`):

```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
FastCGI handler for IIS
"""
from wfastcgi import WSGIHandler
import sys
import os

# Add the Flask app directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

# Import your Flask app
from app import app

if __name__ == '__main__':
    WSGIHandler().run(app)
```

## Step 12: Test the Configuration

### Test Windows Authentication Headers

1. Use the verification script:
   ```powershell
   cd C:\inetpub\wwwroot\your-flask-app\flask_app
   python verify_iis_auth.py
   ```
   Access: `http://localhost:5000/` (for local testing)

2. Deploy to IIS and access: `http://your-server/verify_iis_auth.py` or your main app

3. Check the verification page for:
   - ✅ `REMOTE_USER` header should show: `DOMAIN\username`
   - ✅ `AUTH_USER` header may also be present
   - ✅ Authentication status should show "WORKING"

### Common Headers to Check

- `REMOTE_USER`: Standard header (format: `DOMAIN\username`)
- `AUTH_USER`: IIS-specific header
- `LOGON_USER`: Alternative IIS header
- `HTTP_X_FORWARDED_USER`: If using reverse proxy
- `HTTP_X_REMOTE_USER`: Alternative forwarded header

## Step 13: Troubleshooting

### Issue: Headers Not Appearing

**Solution:**
1. Verify Windows Authentication is enabled (not Anonymous)
2. Check `web.config` has `<windowsAuthentication enabled="true" />`
3. Ensure `REMOTE_USER` is being passed: Check IIS logs
4. Verify user has access to the site

### Issue: 500 Internal Server Error

**Solution:**
1. Check Event Viewer → Windows Logs → Application
2. Verify Python path in `web.config` is correct
3. Check FastCGI settings match `web.config`
4. Verify `handler.fcgi` exists and is accessible
5. Check file permissions on Flask app directory

### Issue: "Handler 'Flask FastCGI' has a bad module"

**Solution:**
1. Verify FastCGI module is installed
2. Check `web.config` handler path is correct
3. Restart IIS: `iisreset` in PowerShell (as Administrator)

### Issue: User Shows as Anonymous

**Solution:**
1. Disable Anonymous Authentication
2. Enable Windows Authentication
3. Check browser settings (some browsers need configuration)
4. Verify user is accessing from domain-joined machine
5. Check IIS authentication providers order

### Issue: Python Module Not Found

**Solution:**
1. Verify `PYTHONPATH` in FastCGI environment variables
2. Check virtual environment is activated (if using)
3. Install missing packages: `pip install package-name`
4. Verify Python path in `web.config`

## Step 14: Security Best Practices

1. **Use HTTPS**: Configure SSL certificate for production
2. **Restrict Access**: Use IP restrictions if needed
3. **Service Account**: Use dedicated service account for app pool (not ApplicationPoolIdentity)
4. **Environment Variables**: Store sensitive data in environment variables, not in code
5. **Headers Validation**: Validate and sanitize user input from headers
6. **Logging**: Enable IIS logging and application logging
7. **Firewall**: Configure Windows Firewall appropriately

## Step 15: Production Checklist

- [ ] Windows Authentication enabled
- [ ] Anonymous Authentication disabled
- [ ] HTTPS configured (SSL certificate)
- [ ] FastCGI configured correctly
- [ ] Environment variables set
- [ ] File permissions configured
- [ ] Application pool identity set
- [ ] Logging enabled
- [ ] Error pages configured
- [ ] Backup strategy in place
- [ ] Monitoring configured

## Alternative: Using HttpPlatformHandler (Recommended for Python 3.5+)

Instead of FastCGI, you can use HttpPlatformHandler which is simpler:

### Install HttpPlatformHandler
1. Download from: https://www.iis.net/downloads/microsoft/httpplatformhandler
2. Install the module

### Update web.config

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <security>
      <authentication>
        <anonymousAuthentication enabled="false" />
        <windowsAuthentication enabled="true" />
      </authentication>
    </security>
    
    <handlers>
      <add name="httpPlatformHandler" path="*" verb="*" 
           modules="httpPlatformHandler" 
           resourceType="Unspecified" />
    </handlers>
    
    <httpPlatform processPath="C:\Python312\python.exe"
                  arguments="C:\inetpub\wwwroot\your-flask-app\flask_app\app.py"
                  stdoutLogEnabled="true"
                  stdoutLogFile="C:\inetpub\logs\stdout.log"
                  startupTimeLimit="20"
                  startupRetryCount="10">
      <environmentVariables>
        <environmentVariable name="PORT" value="%HTTP_PLATFORM_PORT%" />
        <environmentVariable name="DB_SERVER" value="your-sql-server" />
        <!-- Add other environment variables -->
      </environmentVariables>
    </httpPlatform>
  </system.webServer>
</configuration>
```

### Update Flask app.py

Add this at the end of `app.py`:

```python
if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 5000))
    app.run(host='127.0.0.1', port=port)
```

## Additional Resources

- [IIS FastCGI Documentation](https://www.iis.net/learn/application-frameworks/install-and-configure-php-applications-on-iis/using-fastcgi-to-host-php-applications-on-iis)
- [Windows Authentication in IIS](https://docs.microsoft.com/en-us/iis/configuration/system.webserver/security/authentication/windowsauthentication/)
- [Flask Deployment on Windows](https://flask.palletsprojects.com/en/latest/deploying/windows/)
- [wfastcgi Documentation](https://pypi.org/project/wfastcgi/)

## Support

If you encounter issues:
1. Check IIS logs: `C:\inetpub\logs\LogFiles\`
2. Check Windows Event Viewer
3. Use the verification script (`verify_iis_auth.py`) to diagnose header issues
4. Review FastCGI/HttpPlatformHandler logs
