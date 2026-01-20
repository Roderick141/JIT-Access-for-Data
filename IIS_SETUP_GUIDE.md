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

Modify the `get_windows_username()` function to read from IIS headers. **Important:** Flask receives headers without the `HTTP_` prefix that IIS uses internally.

```python
def get_windows_username():
    """
    Get the current Windows username from IIS headers
    
    IIS sets HTTP_REMOTE_USER server variable → URL Rewrite converts to HTTP_REMOTE_USER header
    → Flask receives it as REMOTE_USER (HTTP_ prefix is removed)
    
    Priority order based on reliability:
    1. REMOTE_USER - Most reliable, works with kernel-mode auth
    2. AUTH_USER - Reliable fallback
    3. LOGON_USER - May be empty with kernel-mode auth (don't rely on this)
    """
    # Flask receives headers without HTTP_ prefix
    # IIS internally uses HTTP_REMOTE_USER, but Flask sees REMOTE_USER
    windows_user = (
        request.headers.get('REMOTE_USER') or           # Primary - most reliable
        request.headers.get('AUTH_USER') or             # Fallback 1
        request.headers.get('LOGON_USER') or            # Fallback 2 (may be empty)
        request.headers.get('HTTP_REMOTE_USER') or      # Alternative name (some configs)
        request.headers.get('HTTP_X_FORWARDED_USER') or # If using reverse proxy
        request.headers.get('HTTP_X_REMOTE_USER') or    # Alternative forwarded header
        None
    )
    
    # Development fallback - use environment variables when not running under IIS
    if not windows_user:
        windows_user = os.environ.get('USERNAME') or os.environ.get('USER') or None
    
    # Debug logging (remove in production or use proper logging)
    if not windows_user:
        print("Warning: No Windows username found in headers")
        print(f"Available headers: {list(request.headers.keys())}")
    
    return windows_user
```

**Key Points:**
- `REMOTE_USER` is the most reliable header (works even when `LOGON_USER` is empty)
- Flask automatically removes `HTTP_` prefix from header names
- Always check multiple header names as fallbacks
- Include debug logging during initial setup to verify headers are being received

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
        <!-- CRITICAL: Extract Windows Auth from Server Variables and Set as HTTP Headers -->
        <rule name="Set REMOTE_USER from Server Variables" stopProcessing="false">
          <match url=".*" />
          <conditions>
            <!-- Check if REMOTE_USER server variable exists -->
            <add input="{REMOTE_USER}" pattern=".+" />
          </conditions>
          <serverVariables>
            <!-- Set HTTP header from server variable -->
            <set name="HTTP_REMOTE_USER" value="{REMOTE_USER}" />
          </serverVariables>
          <action type="None" />
        </rule>
        
        <!-- Alternative: Extract from LOGON_USER if REMOTE_USER is empty -->
        <rule name="Set REMOTE_USER from LOGON_USER" stopProcessing="false">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REMOTE_USER}" pattern="^$" />
            <add input="{LOGON_USER}" pattern=".+" />
          </conditions>
          <serverVariables>
            <set name="HTTP_REMOTE_USER" value="{LOGON_USER}" />
            <set name="HTTP_AUTH_USER" value="{LOGON_USER}" />
          </serverVariables>
          <action type="None" />
        </rule>
        
        <!-- Extract from AUTH_USER server variable -->
        <rule name="Set REMOTE_USER from AUTH_USER" stopProcessing="false">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REMOTE_USER}" pattern="^$" />
            <add input="{LOGON_USER}" pattern="^$" />
            <add input="{AUTH_USER}" pattern=".+" />
          </conditions>
          <serverVariables>
            <set name="HTTP_REMOTE_USER" value="{AUTH_USER}" />
            <set name="HTTP_AUTH_USER" value="{AUTH_USER}" />
          </serverVariables>
          <action type="None" />
        </rule>
        
        <!-- Main Flask FastCGI rewrite rule -->
        <rule name="Flask FastCGI" stopProcessing="true">
          <match url="(.*)" ignoreCase="false" />
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
          </conditions>
          <action type="Rewrite" url="handler.fcgi/{R:1}" appendQueryString="true" />
        </rule>
      </rules>
      <!-- Allow server variables to be set -->
      <allowedServerVariables>
        <add name="HTTP_REMOTE_USER" />
        <add name="HTTP_AUTH_USER" />
        <add name="HTTP_LOGON_USER" />
        <add name="HTTP_X_FORWARDED_USER" />
      </allowedServerVariables>
    </rewrite>
    
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

## Step 4a: Understanding IIS Server Variables vs HTTP Headers

**CRITICAL CONCEPT:** IIS stores Windows Authentication information in **Server Variables**, not HTTP headers by default. These server variables need to be explicitly converted to HTTP headers for Flask to access them.

### IIS Server Variables (Available to IIS, not Flask by default):
- `{REMOTE_USER}` - Standard server variable (format: `DOMAIN\username`)
- `{LOGON_USER}` - IIS server variable (may be empty in some configurations)
- `{AUTH_USER}` - IIS server variable (alternative)
- `{AUTH_TYPE}` - Authentication type (usually `Negotiate` or `NTLM`)

### HTTP Headers (What Flask sees):
- `REMOTE_USER` - Standard header (must be set from server variable)
- `HTTP_REMOTE_USER` - Alternative header name
- `AUTH_USER` - IIS-specific header
- `LOGON_USER` - Alternative header

### Why LOGON_USER Might Be Empty

`LOGON_USER` server variable can be empty in these scenarios:
1. **Kernel-mode authentication** is enabled (default) - uses `REMOTE_USER` instead
2. **Integrated Pipeline Mode** - may not populate `LOGON_USER`
3. **FastCGI/HttpPlatformHandler** - doesn't automatically forward server variables
4. **Anonymous authentication** was enabled at some point during request processing

### Solution: Use URL Rewrite to Extract and Forward

The `web.config` above includes URL Rewrite rules that:
1. Check `REMOTE_USER` server variable first (most reliable)
2. Fall back to `LOGON_USER` if `REMOTE_USER` is empty
3. Fall back to `AUTH_USER` if both are empty
4. Set `HTTP_REMOTE_USER` header so Flask can read it

**Note:** Flask reads headers with underscores, so `HTTP_REMOTE_USER` becomes `request.headers.get('REMOTE_USER')` in Flask (IIS automatically converts `HTTP_` prefix).

## Step 4b: Verify Server Variables Are Available

Before configuring headers, verify which server variables IIS is actually setting:

### Method 1: Create a Test ASPX Page (if .NET is available)

Create `test-auth.aspx`:

```aspx
<%@ Page Language="C#" %>
<!DOCTYPE html>
<html>
<head><title>IIS Auth Test</title></head>
<body>
    <h2>Server Variables:</h2>
    <p><strong>REMOTE_USER:</strong> <%= Request.ServerVariables["REMOTE_USER"] %></p>
    <p><strong>LOGON_USER:</strong> <%= Request.ServerVariables["LOGON_USER"] %></p>
    <p><strong>AUTH_USER:</strong> <%= Request.ServerVariables["AUTH_USER"] %></p>
    <p><strong>AUTH_TYPE:</strong> <%= Request.ServerVariables["AUTH_TYPE"] %></p>
    <p><strong>HTTP_REMOTE_USER:</strong> <%= Request.Headers["REMOTE_USER"] %></p>
</body>
</html>
```

### Method 2: Use PowerShell to Check Server Variables

Create a PowerShell script `test-iis-vars.ps1`:

```powershell
# Test IIS Server Variables
Import-Module WebAdministration

$siteName = "JIT-Access-App"  # Your site name
$appPath = "/"

# Get server variables via IIS Manager
Write-Host "Checking IIS Configuration..." -ForegroundColor Green
Write-Host "Site: $siteName" -ForegroundColor Yellow
Write-Host "Path: $appPath" -ForegroundColor Yellow

# Check authentication settings
$auth = Get-WebConfigurationProperty -Filter "system.webServer/security/authentication/windowsAuthentication" -PSPath "IIS:\Sites\$siteName" -Name "enabled"
Write-Host "`nWindows Authentication Enabled: $($auth.Value)" -ForegroundColor $(if($auth.Value){"Green"}else{"Red"})

$anon = Get-WebConfigurationProperty -Filter "system.webServer/security/authentication/anonymousAuthentication" -PSPath "IIS:\Sites\$siteName" -Name "enabled"
Write-Host "Anonymous Authentication Enabled: $($anon.Value)" -ForegroundColor $(if($anon.Value){"Red"}else{"Green"})

Write-Host "`nTo verify server variables, access your site and check IIS logs:" -ForegroundColor Cyan
Write-Host "C:\inetpub\logs\LogFiles\W3SVC*\" -ForegroundColor Yellow
```

### Method 3: Enable Detailed IIS Logging

1. Open IIS Manager
2. Select your website
3. Double-click "Logging"
4. Click "Select Fields"
5. Add these fields:
   - `cs-username` (client username)
   - `cs-authentication` (authentication type)
   - `sc-status` (status code)
6. Access your site and check logs: `C:\inetpub\logs\LogFiles\W3SVC*\`

## Step 4c: Alternative web.config for When LOGON_USER is Empty

If `LOGON_USER` is consistently empty, use this enhanced `web.config` that focuses on `REMOTE_USER`:

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
    
    <rewrite>
      <rules>
        <!-- Primary: REMOTE_USER is most reliable with Windows Auth -->
        <rule name="Set REMOTE_USER Header" stopProcessing="false">
          <match url=".*" />
          <conditions>
            <add input="{REMOTE_USER}" pattern=".+" />
          </conditions>
          <serverVariables>
            <!-- IIS converts HTTP_REMOTE_USER to REMOTE_USER header -->
            <set name="HTTP_REMOTE_USER" value="{REMOTE_USER}" />
            <!-- Also set AUTH_USER for compatibility -->
            <set name="HTTP_AUTH_USER" value="{REMOTE_USER}" />
          </serverVariables>
          <action type="None" />
        </rule>
        
        <!-- Fallback: Try AUTH_USER server variable -->
        <rule name="Set from AUTH_USER" stopProcessing="false">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REMOTE_USER}" pattern="^$" />
            <add input="{AUTH_USER}" pattern=".+" />
          </conditions>
          <serverVariables>
            <set name="HTTP_REMOTE_USER" value="{AUTH_USER}" />
            <set name="HTTP_AUTH_USER" value="{AUTH_USER}" />
          </serverVariables>
          <action type="None" />
        </rule>
        
        <!-- Extract username from AUTH_TYPE if available -->
        <rule name="Extract from AUTH_TYPE" stopProcessing="false">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REMOTE_USER}" pattern="^$" />
            <add input="{AUTH_USER}" pattern="^$" />
            <add input="{AUTH_TYPE}" pattern="Negotiate|NTLM" />
          </conditions>
          <serverVariables>
            <!-- This will be set by Windows Auth module, but we ensure it's forwarded -->
            <set name="HTTP_REMOTE_USER" value="{REMOTE_USER}" />
          </serverVariables>
          <action type="None" />
        </rule>
        
        <!-- Flask FastCGI handler -->
        <rule name="Flask FastCGI" stopProcessing="true">
          <match url="(.*)" />
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
          </conditions>
          <action type="Rewrite" url="handler.fcgi/{R:1}" appendQueryString="true" />
        </rule>
      </rules>
      <allowedServerVariables>
        <add name="HTTP_REMOTE_USER" />
        <add name="HTTP_AUTH_USER" />
        <add name="HTTP_LOGON_USER" />
      </allowedServerVariables>
    </rewrite>
    
    <!-- Rest of configuration... -->
    <handlers>
      <add name="Flask FastCGI" path="handler.fcgi" verb="*" modules="FastCgiModule" 
           scriptProcessor="C:\Python312\python.exe|C:\Python312\Lib\site-packages\wfastcgi.py" 
           resourceType="Unspecified" requireAccess="Script" />
    </handlers>
    
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

## Step 4d: Enable Server Variable Forwarding in FastCGI

FastCGI needs explicit configuration to forward server variables. Update your FastCGI environment variables:

1. Open IIS Manager
2. Select your server → "FastCGI Settings"
3. Find your Python FastCGI application
4. Click "Edit" → "Environment Variables"
5. Add these variables to forward server variables:
   - `REMOTE_USER` = `{REMOTE_USER}` (this won't work directly - use URL Rewrite instead)

**Note:** FastCGI doesn't automatically forward server variables. The URL Rewrite method above is the correct approach.

## Step 4e: Testing Header Forwarding

After configuring URL Rewrite rules, test that headers are being forwarded:

1. **Use the verification script** (`verify_iis_auth.py`):
   - Deploy it to IIS
   - Access: `http://your-server/verify_iis_auth.py`
   - Check which headers are present

2. **Check IIS Failed Request Tracing** (if headers still missing):
   - Enable Failed Request Tracing in IIS Manager
   - Set trace conditions: Status code 200-299
   - Access your site
   - Review trace files: `C:\inetpub\logs\FailedReqLogFiles\`
   - Look for `GENERAL_REQUEST_HEADERS` section

3. **Enable URL Rewrite Logging**:
   - Open IIS Manager → Server → "URL Rewrite"
   - Click "View Server Variables"
   - Enable logging for debugging
   - Check: `C:\inetpub\logs\LogFiles\W3SVC*\`

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

- `REMOTE_USER`: Standard header (format: `DOMAIN\username`) - **Most reliable**
- `AUTH_USER`: IIS-specific header
- `LOGON_USER`: Alternative IIS header (may be empty with kernel-mode auth)
- `HTTP_X_FORWARDED_USER`: If using reverse proxy
- `HTTP_X_REMOTE_USER`: Alternative forwarded header

### Diagnostic: When LOGON_USER is Empty

If `LOGON_USER` server variable is empty, this is **normal** in many IIS configurations. Here's how to diagnose and work around it:

#### Step 1: Check Which Server Variables Are Actually Set

Create a PowerShell diagnostic script `diagnose-iis-auth.ps1`:

```powershell
# Requires: Import-Module WebAdministration
# Run as Administrator

$siteName = "JIT-Access-App"  # Change to your site name

Write-Host "=== IIS Windows Authentication Diagnostic ===" -ForegroundColor Cyan
Write-Host ""

# Check authentication settings
Write-Host "1. Authentication Configuration:" -ForegroundColor Yellow
$winAuth = Get-WebConfigurationProperty -Filter "system.webServer/security/authentication/windowsAuthentication" -PSPath "IIS:\Sites\$siteName" -Name "enabled"
$anonAuth = Get-WebConfigurationProperty -Filter "system.webServer/security/authentication/anonymousAuthentication" -PSPath "IIS:\Sites\$siteName" -Name "enabled"
$kernelMode = Get-WebConfigurationProperty -Filter "system.webServer/security/authentication/windowsAuthentication" -PSPath "IIS:\Sites\$siteName" -Name "useKernelMode"

Write-Host "   Windows Auth Enabled: $($winAuth.Value)" -ForegroundColor $(if($winAuth.Value){"Green"}else{"Red"})
Write-Host "   Anonymous Auth Enabled: $($anonAuth.Value)" -ForegroundColor $(if($anonAuth.Value){"Red"}else{"Green"})
Write-Host "   Kernel-Mode Auth: $($kernelMode.Value)" -ForegroundColor $(if($kernelMode.Value){"Yellow"}else{"Green"})
Write-Host ""

# Check URL Rewrite configuration
Write-Host "2. URL Rewrite Configuration:" -ForegroundColor Yellow
$rewriteEnabled = Get-WebConfigurationProperty -Filter "system.webServer/rewrite" -PSPath "IIS:\Sites\$siteName" -Name "."
if ($rewriteEnabled) {
    Write-Host "   URL Rewrite: Enabled" -ForegroundColor Green
    
    # Check allowed server variables
    $allowedVars = Get-WebConfigurationProperty -Filter "system.webServer/rewrite/allowedServerVariables" -PSPath "IIS:\Sites\$siteName" -Name "collection"
    Write-Host "   Allowed Server Variables:" -ForegroundColor Cyan
    foreach ($var in $allowedVars) {
        Write-Host "     - $($var.name)" -ForegroundColor White
    }
} else {
    Write-Host "   URL Rewrite: Not Configured" -ForegroundColor Red
}
Write-Host ""

# Check recent IIS logs for authentication
Write-Host "3. Recent Authentication in IIS Logs:" -ForegroundColor Yellow
$logPath = "C:\inetpub\logs\LogFiles\W3SVC*"
$latestLog = Get-ChildItem $logPath -Recurse -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestLog) {
    Write-Host "   Latest log: $($latestLog.FullName)" -ForegroundColor Cyan
    $logEntries = Get-Content $latestLog.FullName -Tail 20
    $usernameEntries = $logEntries | Select-String "cs-username"
    if ($usernameEntries) {
        Write-Host "   Found username entries:" -ForegroundColor Green
        $usernameEntries | ForEach-Object { Write-Host "     $_" -ForegroundColor White }
    } else {
        Write-Host "   No username entries found in recent logs" -ForegroundColor Yellow
        Write-Host "   (This may indicate authentication isn't working)" -ForegroundColor Red
    }
} else {
    Write-Host "   No log files found" -ForegroundColor Yellow
}
Write-Host ""

# Recommendations
Write-Host "4. Recommendations:" -ForegroundColor Yellow
if (-not $winAuth.Value) {
    Write-Host "   ❌ Enable Windows Authentication" -ForegroundColor Red
}
if ($anonAuth.Value) {
    Write-Host "   ❌ Disable Anonymous Authentication" -ForegroundColor Red
}
if ($kernelMode.Value) {
    Write-Host "   ⚠️  Kernel-mode auth enabled - LOGON_USER may be empty" -ForegroundColor Yellow
    Write-Host "      Use REMOTE_USER server variable instead" -ForegroundColor Cyan
}
if (-not $rewriteEnabled) {
    Write-Host "   ❌ Configure URL Rewrite to forward server variables" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Diagnostic Complete ===" -ForegroundColor Cyan
```

Run this script to see what's configured and what might be missing.

#### Step 2: Verify Server Variables via IIS Manager

1. Enable **Failed Request Tracing**:
   - IIS Manager → Your Site → "Failed Request Tracing Rules"
   - Add Rule → Status Code: `200-299`
   - Enable tracing

2. Access your site (trigger a request)

3. Check trace files: `C:\inetpub\logs\FailedReqLogFiles\W3SVC*\`
   - Open the XML file
   - Search for `REMOTE_USER`, `LOGON_USER`, `AUTH_USER`
   - These show what IIS actually has available

#### Step 3: Test Server Variable Extraction

Create a simple test to see what server variables IIS has:

**Option A: Use URL Rewrite Test Pattern**

1. IIS Manager → Your Site → URL Rewrite
2. Add Rule → Blank Rule
3. Name: `Test Server Variables`
4. Pattern: `(.*)`
5. Conditions → Add:
   - Input: `{REMOTE_USER}`
   - Check "Track capture groups"
6. Action → Rewrite → URL: `test.aspx?REMOTE_USER={C:0}`
7. Test URL - if you see username in query string, variable exists

**Option B: Use PowerShell to Query Server Variables**

```powershell
# This requires a test page, but shows the concept
# Create test-server-vars.aspx with content from Step 4b
# Then query it programmatically

$response = Invoke-WebRequest -Uri "http://localhost/test-server-vars.aspx" -UseDefaultCredentials
$response.Content
```

#### Step 4: Ensure URL Rewrite Rules Are Correct

The most common issue is URL Rewrite rules not properly extracting server variables. Verify your rules:

1. **Rule Order Matters:**
   ```
   1. Set REMOTE_USER Header (stopProcessing="false")
   2. Set from LOGON_USER (stopProcessing="false") 
   3. Set from AUTH_USER (stopProcessing="false")
   4. Flask FastCGI (stopProcessing="true") ← Last!
   ```

2. **Check Rule Conditions:**
   - Each header-setting rule should check if previous attempts failed
   - Use `logicalGrouping="MatchAll"` for multiple conditions
   - Pattern `^$` means "empty string"

3. **Verify allowedServerVariables:**
   ```xml
   <allowedServerVariables>
     <add name="HTTP_REMOTE_USER" />  <!-- Required! -->
     <add name="HTTP_AUTH_USER" />
   </allowedServerVariables>
   ```
   Without this section, URL Rewrite cannot set HTTP headers.

#### Step 5: Alternative Approach - Use AUTH_USER Instead

If `REMOTE_USER` and `LOGON_USER` are both problematic, try `AUTH_USER`:

```xml
<rule name="Set from AUTH_USER Only" stopProcessing="false">
  <match url=".*" />
  <conditions>
    <add input="{AUTH_USER}" pattern=".+" />
  </conditions>
  <serverVariables>
    <set name="HTTP_REMOTE_USER" value="{AUTH_USER}" />
  </serverVariables>
  <action type="None" />
</rule>
```

#### Step 6: Nuclear Option - Disable Kernel-Mode Authentication

If nothing else works:

1. IIS Manager → Your Site → Authentication → Windows Authentication
2. Advanced Settings
3. Uncheck "Enable Kernel-mode authentication"
4. Restart IIS: `iisreset`
5. Test again - `LOGON_USER` should now populate

**Warning:** This may impact performance. Only use if necessary.

#### Expected Behavior Summary

| Configuration | REMOTE_USER | LOGON_USER | AUTH_USER |
|--------------|-------------|------------|-----------|
| Kernel-mode ON | ✅ Usually set | ❌ Often empty | ✅ Usually set |
| Kernel-mode OFF | ✅ Set | ✅ Set | ✅ Set |
| Integrated Pipeline | ✅ Set | ✅ Set | ✅ Set |
| Classic Pipeline | ✅ Set | ⚠️ May vary | ✅ Set |

**Best Practice:** Always use `REMOTE_USER` as primary, with `AUTH_USER` as fallback. Don't rely on `LOGON_USER` if kernel-mode auth is enabled.

## Step 13: Troubleshooting

### Issue: Headers Not Appearing / LOGON_USER is Empty

**Symptoms:**
- Flask app shows `None` for Windows username
- Verification script shows no `REMOTE_USER` header
- `LOGON_USER` server variable is empty

**Root Causes:**
1. **Server variables not converted to HTTP headers** - Most common issue
2. **Kernel-mode authentication** - May not populate `LOGON_USER`
3. **URL Rewrite rules not configured** - Server variables exist but aren't forwarded
4. **FastCGI not forwarding variables** - FastCGI doesn't auto-forward server variables

**Step-by-Step Solution:**

1. **Verify Server Variables Exist:**
   ```powershell
   # Check IIS logs for cs-username field
   Get-Content C:\inetpub\logs\LogFiles\W3SVC*\*.log -Tail 50 | Select-String "cs-username"
   ```
   If you see usernames in logs, server variables exist but aren't being forwarded.

2. **Verify URL Rewrite Rules Are Active:**
   - Open IIS Manager → Your Site → "URL Rewrite"
   - Verify rules are listed and enabled
   - Check `allowedServerVariables` includes `HTTP_REMOTE_USER`

3. **Test Server Variables Directly:**
   Create `test-server-vars.aspx` (if ASP.NET available):
   ```aspx
   <%@ Page Language="C#" %>
   REMOTE_USER: <%= Request.ServerVariables["REMOTE_USER"] %><br>
   LOGON_USER: <%= Request.ServerVariables["LOGON_USER"] %><br>
   AUTH_USER: <%= Request.ServerVariables["AUTH_USER"] %><br>
   AUTH_TYPE: <%= Request.ServerVariables["AUTH_TYPE"] %><br>
   ```
   Access this page - if variables show here but not in Flask, forwarding is the issue.

4. **Enable URL Rewrite Logging:**
   ```powershell
   # Enable detailed logging
   Set-WebConfigurationProperty -PSPath "MACHINE/WEBROOT/APPHOST" -Filter "system.webServer/rewrite/rewriteMaps" -Name "." -Value @{}
   ```
   Check logs: `C:\inetpub\logs\LogFiles\W3SVC*\`

5. **Verify web.config Syntax:**
   - Use XML validator: `https://www.xmlvalidation.com/`
   - Check for typos in server variable names
   - Ensure `allowedServerVariables` section exists

6. **Check Authentication Order:**
   - Anonymous must be **disabled**
   - Windows Authentication must be **enabled**
   - Order matters: Windows Auth should process before URL Rewrite

7. **Test with PowerShell:**
   ```powershell
   # Check current authentication settings
   Get-WebConfigurationProperty -Filter "system.webServer/security/authentication/windowsAuthentication" -PSPath "IIS:\Sites\YourSiteName" -Name "enabled"
   Get-WebConfigurationProperty -Filter "system.webServer/security/authentication/anonymousAuthentication" -PSPath "IIS:\Sites\YourSiteName" -Name "enabled"
   ```

8. **Force Header Forwarding (Nuclear Option):**
   If URL Rewrite isn't working, use `httpProtocol` to set headers:
   ```xml
   <httpProtocol>
     <customHeaders>
       <!-- This won't work - customHeaders can't read server variables -->
       <!-- Use URL Rewrite instead -->
     </customHeaders>
   </httpProtocol>
   ```
   **Note:** `customHeaders` cannot read server variables. URL Rewrite is required.

9. **Check Application Pool Identity:**
   - Application Pool → Advanced Settings → Identity
   - Should be `ApplicationPoolIdentity` or service account
   - Ensure "Load User Profile" = `True`

10. **Verify Kernel-Mode Authentication:**
    - Windows Auth → Advanced Settings
    - If "Enable Kernel-mode authentication" = `True`, `LOGON_USER` may be empty
    - `REMOTE_USER` should still work
    - Try disabling kernel-mode auth temporarily to test

### Issue: REMOTE_USER Header Exists But Flask Can't Read It

**Symptoms:**
- Verification script shows `REMOTE_USER` header
- Flask `request.headers.get('REMOTE_USER')` returns `None`

**Solution:**
1. **Check Header Name in Flask:**
   Flask may receive it as `HTTP_REMOTE_USER`:
   ```python
   # Try both variations
   user = request.headers.get('REMOTE_USER') or request.headers.get('HTTP_REMOTE_USER')
   ```

2. **Enable Request Logging in Flask:**
   Add to your Flask app temporarily:
   ```python
   @app.before_request
   def log_headers():
       print("All headers:", dict(request.headers))
       print("REMOTE_USER:", request.headers.get('REMOTE_USER'))
       print("HTTP_REMOTE_USER:", request.headers.get('HTTP_REMOTE_USER'))
   ```

3. **Check wfastcgi Header Handling:**
   wfastcgi may modify header names. Check wfastcgi logs or try:
   ```python
   # Get all headers starting with REMOTE
   remote_headers = {k: v for k, v in request.headers if 'REMOTE' in k.upper()}
   print(remote_headers)
   ```

### Issue: Headers Appear in Some Requests But Not Others

**Symptoms:**
- First request works, subsequent requests fail
- Headers appear for some URLs but not others

**Solution:**
1. **Check URL Rewrite Rule Order:**
   - Header-setting rules must run **before** FastCGI rewrite rule
   - Use `stopProcessing="false"` on header rules
   - Use `stopProcessing="true"` only on FastCGI rule

2. **Verify Rule Conditions:**
   - Header rules should match `url=".*"` (all URLs)
   - FastCGI rule should exclude files: `matchType="IsFile" negate="true"`

3. **Check Static File Handling:**
   - Static files bypass URL Rewrite
   - Ensure Flask handles static files or configure separate handler

4. **Session/Caching Issues:**
   - Clear browser cache
   - Try incognito/private browsing
   - Check if headers are cached incorrectly

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

## Quick Reference: Header Forwarding Checklist

When `LOGON_USER` is empty or headers aren't appearing, use this checklist:

### ✅ Pre-Deployment Checklist

- [ ] Windows Authentication enabled
- [ ] Anonymous Authentication disabled  
- [ ] URL Rewrite module installed
- [ ] `web.config` has URL Rewrite rules to extract server variables
- [ ] `allowedServerVariables` section includes `HTTP_REMOTE_USER`
- [ ] Header-setting rules run **before** FastCGI rewrite rule
- [ ] FastCGI rewrite rule has `stopProcessing="true"`

### ✅ Server Variable Priority (Use This Order)

1. **`{REMOTE_USER}`** - Most reliable, works with kernel-mode auth
2. **`{AUTH_USER}`** - Reliable fallback
3. **`{LOGON_USER}`** - May be empty with kernel-mode auth (don't rely on it)

### ✅ Flask Code Pattern

```python
def get_windows_username():
    """
    Get Windows username from IIS headers
    Priority: REMOTE_USER > AUTH_USER > LOGON_USER
    """
    # Flask receives headers without HTTP_ prefix
    # IIS sets HTTP_REMOTE_USER → Flask sees REMOTE_USER
    windows_user = (
        request.headers.get('REMOTE_USER') or      # Primary
        request.headers.get('AUTH_USER') or         # Fallback 1
        request.headers.get('LOGON_USER') or       # Fallback 2 (may be empty)
        request.headers.get('HTTP_REMOTE_USER') or # Alternative name
        None
    )
    
    # Development fallback
    if not windows_user:
        windows_user = os.environ.get('USERNAME') or os.environ.get('USER')
    
    return windows_user
```

### ✅ URL Rewrite Rule Pattern

```xml
<!-- Extract REMOTE_USER server variable and set as HTTP header -->
<rule name="Set REMOTE_USER Header" stopProcessing="false">
  <match url=".*" />
  <conditions>
    <add input="{REMOTE_USER}" pattern=".+" />
  </conditions>
  <serverVariables>
    <set name="HTTP_REMOTE_USER" value="{REMOTE_USER}" />
  </serverVariables>
  <action type="None" />
</rule>
```

**Key Points:**
- `stopProcessing="false"` allows other rules to run
- `pattern=".+"` means "not empty"
- `HTTP_REMOTE_USER` becomes `REMOTE_USER` header in Flask
- Must have `<allowedServerVariables>` section

### ✅ Common Mistakes to Avoid

1. ❌ **Relying on LOGON_USER** - Often empty with kernel-mode auth
2. ❌ **Missing allowedServerVariables** - URL Rewrite can't set headers without this
3. ❌ **Wrong rule order** - Header rules must come before FastCGI rule
4. ❌ **Anonymous auth enabled** - Prevents Windows auth from working
5. ❌ **Using customHeaders** - Cannot read server variables, use URL Rewrite instead

### ✅ Diagnostic Commands

```powershell
# Check authentication status
Get-WebConfigurationProperty -Filter "system.webServer/security/authentication/windowsAuthentication" -PSPath "IIS:\Sites\YourSite" -Name "enabled"

# Check URL Rewrite allowed variables
Get-WebConfigurationProperty -Filter "system.webServer/rewrite/allowedServerVariables" -PSPath "IIS:\Sites\YourSite" -Name "collection"

# View recent authentication in logs
Get-Content C:\inetpub\logs\LogFiles\W3SVC*\*.log -Tail 50 | Select-String "cs-username"

# Restart IIS
iisreset
```

## Support

If you encounter issues:
1. **Use the verification script** (`verify_iis_auth.py`) - Shows exactly what headers Flask receives
2. **Check IIS logs** - `C:\inetpub\logs\LogFiles\` - Look for `cs-username` field
3. **Enable Failed Request Tracing** - Shows server variables available to IIS
4. **Check Windows Event Viewer** - Application logs may show authentication errors
5. **Review FastCGI/HttpPlatformHandler logs** - May show header forwarding issues
6. **Run diagnostic script** - Use `diagnose-iis-auth.ps1` from Step 12

### Getting Help

When asking for help, provide:
- Output from `verify_iis_auth.py` (shows headers Flask receives)
- Output from `diagnose-iis-auth.ps1` (shows IIS configuration)
- Relevant section from IIS logs showing authentication
- Your `web.config` URL Rewrite section
- Whether kernel-mode authentication is enabled
