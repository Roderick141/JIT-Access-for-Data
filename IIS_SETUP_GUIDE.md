# IIS Setup Guide for Flask with Windows Authentication

This guide walks you through configuring IIS to run your Flask application with Windows Authentication, ensuring that Windows user credentials are passed through to Flask via HTTP headers.

## Prerequisites

- Windows Server with IIS installed
- Python installed on the server
- Flask application ready to deploy
- IIS URL Rewrite module installed
- Application Request Routing (ARR) module installed (optional, for reverse proxy)

## Choose Your Deployment Method

Before proceeding, choose your deployment method:

- **FastCGI (wfastcgi)** - Traditional method, more complex setup, good for existing deployments
- **HttpPlatformHandler** - Modern method, simpler setup, recommended for new deployments (Python 3.5+)

**This guide covers FastCGI first, then HttpPlatformHandler as an alternative.**

---

# Part 1: FastCGI Deployment Method

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

## Step 3: Understand IIS Server Variables vs HTTP Headers

**CRITICAL CONCEPT:** IIS stores Windows Authentication information in **Server Variables**, not HTTP headers by default. These server variables need to be explicitly converted to HTTP headers for Flask to access them.

### IIS Server Variables (Available to IIS, not Flask by default):
- `{REMOTE_USER}` - Standard server variable (format: `DOMAIN\username`) - **Most reliable**
- `{LOGON_USER}` - IIS server variable (may be empty with kernel-mode auth)
- `{AUTH_USER}` - IIS server variable (reliable fallback)
- `{AUTH_TYPE}` - Authentication type (usually `Negotiate` or `NTLM`)

### HTTP Headers (What Flask sees):
- `REMOTE_USER` - Standard header (must be set from server variable)
- `AUTH_USER` - IIS-specific header
- `LOGON_USER` - Alternative header (may be empty)

### Why LOGON_USER Might Be Empty

`LOGON_USER` server variable can be empty in these scenarios:
1. **Kernel-mode authentication** is enabled (default) - uses `REMOTE_USER` instead
2. **Integrated Pipeline Mode** - may not populate `LOGON_USER`
3. **FastCGI/HttpPlatformHandler** - doesn't automatically forward server variables
4. **Anonymous authentication** was enabled at some point during request processing

### Solution: Use URL Rewrite to Extract and Forward

We'll use URL Rewrite rules that:
1. Check `REMOTE_USER` server variable first (most reliable)
2. Fall back to `LOGON_USER` if `REMOTE_USER` is empty
3. Fall back to `AUTH_USER` if both are empty
4. Set `HTTP_REMOTE_USER` header so Flask can read it

**Note:** Flask reads headers with underscores, so `HTTP_REMOTE_USER` becomes `request.headers.get('REMOTE_USER')` in Flask (IIS automatically converts `HTTP_` prefix).

## Step 4: Configure Your Flask Application

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
    
    return windows_user
```

**Key Points:**
- `REMOTE_USER` is the most reliable header (works even when `LOGON_USER` is empty)
- Flask automatically removes `HTTP_` prefix from header names
- Always check multiple header names as fallbacks

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
   - `PYTHONPATH` = `C:\inetpub\wwwroot\your-flask-app\flask_app`
   - Add your database connection variables (DB_SERVER, DB_NAME, etc.)

**Important:** FastCGI doesn't automatically forward server variables. We'll use URL Rewrite in `web.config` to handle this.

## Step 6: Create handler.fcgi File

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

## Step 7: Unlock IIS Configuration Sections

**IMPORTANT:** IIS locks certain configuration sections at the server level by default. You must unlock them before your `web.config` can override these settings.

### Method 1: Using PowerShell (Recommended)

Run PowerShell as Administrator and execute:

```powershell
# Unlock authentication section (required for Windows Auth)
Unlock-WebConfiguration -Filter "system.webServer/security/authentication" -PSPath "MACHINE/WEBROOT/APPHOST"

# Unlock handlers section (required for FastCGI handler)
Unlock-WebConfiguration -Filter "system.webServer/handlers" -PSPath "MACHINE/WEBROOT/APPHOST"

# Unlock FastCGI section (required for FastCGI settings)
Unlock-WebConfiguration -Filter "system.webServer/fastCgi" -PSPath "MACHINE/WEBROOT/APPHOST"

# Unlock rewrite/allowedServerVariables (required for URL Rewrite header forwarding)
Unlock-WebConfiguration -Filter "system.webServer/rewrite/allowedServerVariables" -PSPath "MACHINE/WEBROOT/APPHOST"

# Verify unlocks were successful
Get-WebConfigurationLock -Filter "system.webServer/security/authentication" -PSPath "MACHINE/WEBROOT/APPHOST"
Get-WebConfigurationLock -Filter "system.webServer/handlers" -PSPath "MACHINE/WEBROOT/APPHOST"
Get-WebConfigurationLock -Filter "system.webServer/fastCgi" -PSPath "MACHINE/WEBROOT/APPHOST"
Get-WebConfigurationLock -Filter "system.webServer/rewrite/allowedServerVariables" -PSPath "MACHINE/WEBROOT/APPHOST"
```

If the commands return nothing, the sections are unlocked. If they return lock information, the unlock didn't work (check you're running as Administrator).

### Method 2: Using appcmd.exe

Run Command Prompt as Administrator and execute:

```cmd
cd C:\Windows\System32\inetsrv

# Unlock authentication section
appcmd unlock config -section:system.webServer/security/authentication

# Unlock handlers section
appcmd unlock config -section:system.webServer/handlers

# Unlock FastCGI section
appcmd unlock config -section:system.webServer/fastCgi

# Unlock rewrite/allowedServerVariables
appcmd unlock config -section:system.webServer/rewrite/allowedServerVariables
```

### Method 3: Manual Edit (Advanced)

If the above methods don't work, you can manually edit `applicationHost.config`:

1. Navigate to: `C:\Windows\System32\inetsrv\config\applicationHost.config`
2. Find the `<sectionGroup name="system.webServer">` section
3. Look for these sections and remove `overrideModeDefault="Deny"` or change it to `overrideModeDefault="Allow"`:
   - `<section name="security" overrideModeDefault="Deny" />` → Change to `Allow`
   - `<section name="handlers" overrideModeDefault="Deny" />` → Change to `Allow`
   - `<section name="fastCgi" overrideModeDefault="Deny" />` → Change to `Allow`
4. Save the file (backup first!)
5. Restart IIS: `iisreset`

**Warning:** Manual editing can break IIS if done incorrectly. Always backup first!

### Verify Unlocks

After unlocking, verify by trying to save a test `web.config` or check in IIS Manager:
- IIS Manager → Your Site → Configuration Editor
- Navigate to the sections above
- If you can edit them, they're unlocked

## Step 8: Create web.config for IIS

Create a `web.config` file in your Flask application root directory (`flask_app` folder):

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
    
    <!-- URL Rewrite Rules - Extract Windows Auth from Server Variables -->
    <rewrite>
      <rules>
        <!-- CRITICAL: Extract REMOTE_USER server variable and set as HTTP header -->
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
        
        <!-- Main Flask FastCGI rewrite rule - MUST BE LAST -->
        <rule name="Flask FastCGI" stopProcessing="true">
          <match url="(.*)" ignoreCase="false" />
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
          </conditions>
          <action type="Rewrite" url="handler.fcgi/{R:1}" appendQueryString="true" />
        </rule>
      </rules>
      <!-- Allow server variables to be set - REQUIRED -->
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
          <environmentVariable name="PYTHONPATH" value="C:\inetpub\wwwroot\your-flask-app\flask_app" />
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
- `C:\inetpub\wwwroot\your-flask-app\flask_app` → Your Flask app directory
- Update environment variables with your actual values

## Step 9: Create IIS Application

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

## Step 10: Configure Application Pool

1. In IIS Manager, select "Application Pools"
2. Select your application pool
3. Click "Advanced Settings"
4. Configure:
   - **.NET CLR Version**: `No Managed Code`
   - **Managed Pipeline Mode**: `Integrated`
   - **Identity**: `ApplicationPoolIdentity` (or specific service account)
   - **Load User Profile**: `True` (important for Python)
5. Click "OK"

## Step 11: Enable Windows Authentication

1. Select your website in IIS Manager
2. Double-click "Authentication"
3. Right-click "Anonymous Authentication" → "Disable"
4. Right-click "Windows Authentication" → "Enable"
5. Right-click "Windows Authentication" → "Advanced Settings"
6. Configure:
   - **Extended Protection**: `Off` (or `Accept` if your environment supports it)
   - **Enable Kernel-mode authentication**: `True` (recommended for performance)

## Step 12: Configure Provider Settings (Optional)

1. Select "Windows Authentication" → "Providers"
2. Ensure providers are in this order:
   - `Negotiate` (first)
   - `NTLM` (second)

## Step 13: Set Permissions

### File System Permissions
1. Right-click your Flask app folder → "Properties" → "Security"
2. Add permissions for:
   - `IIS_IUSRS`: Read & Execute
   - `IIS AppPool\YourAppPoolName`: Read & Execute
   - Your service account (if using): Read & Execute

### IIS Manager Permissions
1. Select your website → "Edit Permissions" → "Security"
2. Ensure `IIS_IUSRS` has appropriate permissions

## Step 14: Test the Configuration

### Test Windows Authentication Headers

1. **Use the verification script** (`verify_iis_auth.py`):
   - Deploy it to IIS (copy to your `flask_app` directory)
   - Access: `http://your-server/verify_iis_auth.py`
   - Check which headers are present

2. **Check the verification page for:**
   - ✅ `REMOTE_USER` header should show: `DOMAIN\username`
   - ✅ `AUTH_USER` header may also be present
   - ✅ Authentication status should show "WORKING"

### Common Headers to Check

- `REMOTE_USER`: Standard header (format: `DOMAIN\username`) - **Most reliable**
- `AUTH_USER`: IIS-specific header
- `LOGON_USER`: Alternative IIS header (may be empty with kernel-mode auth)
- `HTTP_X_FORWARDED_USER`: If using reverse proxy
- `HTTP_X_REMOTE_USER`: Alternative forwarded header

---

# Part 2: HttpPlatformHandler Deployment Method (Alternative)

HttpPlatformHandler is simpler and recommended for new deployments.

## Step 1: Install HttpPlatformHandler

1. Download from: https://www.iis.net/downloads/microsoft/httpplatformhandler
2. Install the module

## Step 2: Install Python and Flask Dependencies

Same as FastCGI method (Step 2 above).

## Step 3: Understand IIS Server Variables vs HTTP Headers

Same as FastCGI method (Step 3 above).

## Step 4: Configure Your Flask Application

Same as FastCGI method (Step 4 above) - update `auth.py` to read headers.

## Step 5: Update Flask app.py

Add this at the end of `app.py`:

```python
if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 5000))
    app.run(host='127.0.0.1', port=port)
```

## Step 6: Unlock IIS Configuration Sections

**IMPORTANT:** IIS locks certain configuration sections at the server level by default. You must unlock them before your `web.config` can override these settings.

Follow **Step 7** from the FastCGI method above to unlock the required sections. For HttpPlatformHandler, you need to unlock:
- `system.webServer/security/authentication`
- `system.webServer/handlers`
- `system.webServer/rewrite/allowedServerVariables`

(You don't need to unlock `fastCgi` for HttpPlatformHandler)

## Step 7: Create web.config for HttpPlatformHandler

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
    
    <!-- URL Rewrite Rules - Extract Windows Auth from Server Variables -->
    <rewrite>
      <rules>
        <!-- Extract REMOTE_USER server variable and set as HTTP header -->
        <rule name="Set REMOTE_USER Header" stopProcessing="false">
          <match url=".*" />
          <conditions>
            <add input="{REMOTE_USER}" pattern=".+" />
          </conditions>
          <serverVariables>
            <set name="HTTP_REMOTE_USER" value="{REMOTE_USER}" />
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
      </rules>
      <allowedServerVariables>
        <add name="HTTP_REMOTE_USER" />
        <add name="HTTP_AUTH_USER" />
      </allowedServerVariables>
    </rewrite>
    
    <!-- HttpPlatformHandler Configuration -->
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
        <environmentVariable name="DB_NAME" value="your-database" />
        <environmentVariable name="DB_USERNAME" value="your-service-account" />
        <environmentVariable name="DB_PASSWORD" value="your-password" />
        <environmentVariable name="SECRET_KEY" value="your-secret-key" />
      </environmentVariables>
    </httpPlatform>
  </system.webServer>
</configuration>
```

## Step 8: Create IIS Application and Configure

Follow Steps 9-14 from the FastCGI method above (Create IIS Application, Configure Application Pool, Enable Windows Authentication, Set Permissions, Test).

---

# Part 3: Troubleshooting and Diagnostics

## Diagnostic: When LOGON_USER is Empty

If `LOGON_USER` server variable is empty, this is **normal** in many IIS configurations. Here's how to diagnose and work around it:

### Step 1: Check Which Server Variables Are Actually Set

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

### Step 2: Verify Server Variables via IIS Manager

1. Enable **Failed Request Tracing**:
   - IIS Manager → Your Site → "Failed Request Tracing Rules"
   - Add Rule → Status Code: `200-299`
   - Enable tracing

2. Access your site (trigger a request)

3. Check trace files: `C:\inetpub\logs\FailedReqLogFiles\W3SVC*\`
   - Open the XML file
   - Search for `REMOTE_USER`, `LOGON_USER`, `AUTH_USER`
   - These show what IIS actually has available

### Expected Behavior Summary

| Configuration | REMOTE_USER | LOGON_USER | AUTH_USER |
|--------------|-------------|------------|-----------|
| Kernel-mode ON | ✅ Usually set | ❌ Often empty | ✅ Usually set |
| Kernel-mode OFF | ✅ Set | ✅ Set | ✅ Set |
| Integrated Pipeline | ✅ Set | ✅ Set | ✅ Set |
| Classic Pipeline | ✅ Set | ⚠️ May vary | ✅ Set |

**Best Practice:** Always use `REMOTE_USER` as primary, with `AUTH_USER` as fallback. Don't rely on `LOGON_USER` if kernel-mode auth is enabled.

## Common Issues and Solutions

### Issue: Headers Not Appearing / LOGON_USER is Empty

**Symptoms:**
- Flask app shows `None` for Windows username
- Verification script shows no `REMOTE_USER` header
- `LOGON_USER` server variable is empty

**Root Causes:**
1. **Server variables not converted to HTTP headers** - Most common issue
2. **Kernel-mode authentication** - May not populate `LOGON_USER`
3. **URL Rewrite rules not configured** - Server variables exist but aren't forwarded
4. **FastCGI/HttpPlatformHandler not forwarding variables** - Doesn't auto-forward server variables

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

3. **Verify web.config Syntax:**
   - Use XML validator: `https://www.xmlvalidation.com/`
   - Check for typos in server variable names
   - Ensure `allowedServerVariables` section exists

4. **Check Authentication Order:**
   - Anonymous must be **disabled**
   - Windows Authentication must be **enabled**
   - Order matters: Windows Auth should process before URL Rewrite

5. **Check Application Pool Identity:**
   - Application Pool → Advanced Settings → Identity
   - Should be `ApplicationPoolIdentity` or service account
   - Ensure "Load User Profile" = `True`

6. **Verify Kernel-Mode Authentication:**
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

### Issue: Headers Appear in Some Requests But Not Others

**Symptoms:**
- First request works, subsequent requests fail
- Headers appear for some URLs but not others

**Solution:**
1. **Check URL Rewrite Rule Order:**
   - Header-setting rules must run **before** FastCGI/HttpPlatformHandler rewrite rule
   - Use `stopProcessing="false"` on header rules
   - Use `stopProcessing="true"` only on final rewrite rule

2. **Verify Rule Conditions:**
   - Header rules should match `url=".*"` (all URLs)
   - Final rewrite rule should exclude files: `matchType="IsFile" negate="true"`

### Issue: "This configuration section cannot be used at this path" or "Section is locked"

**Symptoms:**
- Error when saving `web.config`
- Error message: "This configuration section cannot be used at this path. This happens when the section is locked at a parent level"
- Error occurs on line 7 or other early lines of `web.config`

**Solution:**
This means IIS configuration sections are locked. You must unlock them first:

1. **Unlock using PowerShell (as Administrator):**
   ```powershell
   # Unlock authentication section
   Unlock-WebConfiguration -Filter "system.webServer/security/authentication" -PSPath "MACHINE/WEBROOT/APPHOST"
   
   # Unlock handlers section
   Unlock-WebConfiguration -Filter "system.webServer/handlers" -PSPath "MACHINE/WEBROOT/APPHOST"
   
   # Unlock FastCGI section (FastCGI only)
   Unlock-WebConfiguration -Filter "system.webServer/fastCgi" -PSPath "MACHINE/WEBROOT/APPHOST"
   
   # Unlock rewrite/allowedServerVariables
   Unlock-WebConfiguration -Filter "system.webServer/rewrite/allowedServerVariables" -PSPath "MACHINE/WEBROOT/APPHOST"
   ```

2. **Or unlock using appcmd (as Administrator):**
   ```cmd
   cd C:\Windows\System32\inetsrv
   appcmd unlock config -section:system.webServer/security/authentication
   appcmd unlock config -section:system.webServer/handlers
   appcmd unlock config -section:system.webServer/fastCgi
   appcmd unlock config -section:system.webServer/rewrite/allowedServerVariables
   ```

3. **Restart IIS:**
   ```powershell
   iisreset
   ```

4. **Verify unlock worked:**
   ```powershell
   Get-WebConfigurationLock -Filter "system.webServer/security/authentication" -PSPath "MACHINE/WEBROOT/APPHOST"
   ```
   If this returns nothing, the section is unlocked.

**Note:** See Step 7 (FastCGI) or Step 6 (HttpPlatformHandler) for detailed unlock instructions.

### Issue: 500 Internal Server Error

**Solution:**
1. Check Event Viewer → Windows Logs → Application
2. Verify Python path in `web.config` is correct
3. Check FastCGI/HttpPlatformHandler settings match `web.config`
4. Verify `handler.fcgi` exists (FastCGI) or `app.py` is correct (HttpPlatformHandler)
5. Check file permissions on Flask app directory
6. **Check if configuration sections are locked** (see issue above)

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
1. Verify `PYTHONPATH` in FastCGI/HttpPlatformHandler environment variables
2. Check virtual environment is activated (if using)
3. Install missing packages: `pip install package-name`
4. Verify Python path in `web.config`

---

# Part 4: Security Best Practices and Quick Reference

## Security Best Practices

1. **Use HTTPS**: Configure SSL certificate for production
2. **Restrict Access**: Use IP restrictions if needed
3. **Service Account**: Use dedicated service account for app pool (not ApplicationPoolIdentity)
4. **Environment Variables**: Store sensitive data in environment variables, not in code
5. **Headers Validation**: Validate and sanitize user input from headers
6. **Logging**: Enable IIS logging and application logging
7. **Firewall**: Configure Windows Firewall appropriately

## Production Checklist

- [ ] Windows Authentication enabled
- [ ] Anonymous Authentication disabled
- [ ] HTTPS configured (SSL certificate)
- [ ] FastCGI/HttpPlatformHandler configured correctly
- [ ] URL Rewrite rules configured with `allowedServerVariables`
- [ ] Environment variables set
- [ ] File permissions configured
- [ ] Application pool identity set
- [ ] Logging enabled
- [ ] Error pages configured
- [ ] Backup strategy in place
- [ ] Monitoring configured
- [ ] Verification script tested and headers confirmed

## Quick Reference: Header Forwarding Checklist

When `LOGON_USER` is empty or headers aren't appearing, use this checklist:

### ✅ Pre-Deployment Checklist

- [ ] IIS configuration sections unlocked (authentication, handlers, fastCgi, rewrite/allowedServerVariables)
- [ ] Windows Authentication enabled
- [ ] Anonymous Authentication disabled  
- [ ] URL Rewrite module installed
- [ ] `web.config` has URL Rewrite rules to extract server variables
- [ ] `allowedServerVariables` section includes `HTTP_REMOTE_USER`
- [ ] Header-setting rules run **before** FastCGI/HttpPlatformHandler rewrite rule
- [ ] Final rewrite rule has `stopProcessing="true"`

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

1. ❌ **Not unlocking IIS sections** - Configuration sections locked at parent level will cause errors
2. ❌ **Relying on LOGON_USER** - Often empty with kernel-mode auth
3. ❌ **Missing allowedServerVariables** - URL Rewrite can't set headers without this
4. ❌ **Wrong rule order** - Header rules must come before FastCGI/HttpPlatformHandler rule
5. ❌ **Anonymous auth enabled** - Prevents Windows auth from working
6. ❌ **Using customHeaders** - Cannot read server variables, use URL Rewrite instead

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
6. **Run diagnostic script** - Use `diagnose-iis-auth.ps1` from Part 3

### Getting Help

When asking for help, provide:
- Output from `verify_iis_auth.py` (shows headers Flask receives)
- Output from `diagnose-iis-auth.ps1` (shows IIS configuration)
- Relevant section from IIS logs showing authentication
- Your `web.config` URL Rewrite section
- Whether kernel-mode authentication is enabled
- Which deployment method you're using (FastCGI or HttpPlatformHandler)

## Additional Resources

- [IIS FastCGI Documentation](https://www.iis.net/learn/application-frameworks/install-and-configure-php-applications-on-iis/using-fastcgi-to-host-php-applications-on-iis)
- [Windows Authentication in IIS](https://docs.microsoft.com/en-us/iis/configuration/system.webserver/security/authentication/windowsauthentication/)
- [Flask Deployment on Windows](https://flask.palletsprojects.com/en/latest/deploying/windows/)
- [wfastcgi Documentation](https://pypi.org/project/wfastcgi/)
- [HttpPlatformHandler Documentation](https://docs.microsoft.com/en-us/iis/extensions/httpplatformhandler/httpplatformhandler-configuration-reference)
