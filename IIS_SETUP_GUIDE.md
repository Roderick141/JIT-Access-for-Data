# IIS Setup Guide for Flask with Windows Authentication using YARP Gateway

This guide walks you through deploying your Flask application with Windows Authentication using a YARP (Yet Another Reverse Proxy) gateway running in IIS, with Flask running on Waitress as a Windows service.

## Architecture Overview

```
Internet → IIS (Windows Auth) → YARP Gateway (.NET) → Waitress (Python WSGI) → Flask App
                                    ↓
                            Adds X-Remote-User header
```

**Components:**
1. **IIS** - Handles Windows Authentication
2. **YARP Gateway** - .NET reverse proxy that extracts Windows Auth user and forwards as `X-Remote-User` header
3. **Waitress** - Python WSGI (Web Server Gateway Interfact) server running Flask as a Windows service
4. **Flask App** - Your application reading `X-Remote-User` header

---

## Prerequisites

- Windows Server with IIS installed
- Python 3.8+ installed
- .NET SDK 8.0 (LTS version recommended)
- ASP.NET Core Hosting Bundle (same version as SDK)
- Visual Studio or .NET CLI tools
- Administrative access to the server

---

## Part 1: Install Prerequisites

### Step 1: Install .NET SDK

1. Download .NET SDK (x64) from: https://dotnet.microsoft.com/download/dotnet/
2. Choose the **LTS version** (recommended: .NET 8.0)
3. Download the **SDK** (not just Runtime)
4. During installation:
   - ✅ Leave "Add to PATH" checked
   - Complete the installation
5. Verify installation:
   ```powershell
   dotnet --version
   ```

### Step 2: Install ASP.NET Core Hosting Bundle

1. Download ASP.NET Core Hosting Bundle from: https://dotnet.microsoft.com/download/dotnet/
2. **Important:** Use the same version as your SDK (e.g., if SDK is 8.0, use Hosting Bundle 8.0)
3. Install the bundle
4. Restart IIS:
   ```powershell
   iisreset
   ```

### Step 3: Install Python and Flask Dependencies

1. Install Python 3.8 or higher
2. Create a virtual environment:
   ```powershell
   cd C:\apps\flaskapp  # or your preferred location
   python -m venv .venv
   .venv\Scripts\activate
   ```
3. Install dependencies:
   ```powershell
   pip install flask pyodbc python-dotenv waitress pywin32
   ```

---

## Part 2: Configure YARP Gateway

### Step 1: Configure appsettings.json

Update `appsettings.json`:

```json
{
  "ReverseProxy": {
    "Routes": {
      "flask": {
        "ClusterId": "flaskCluster",
        "Match": { "Path": "{**catch-all}" }
      }
    },
    "Clusters": {
      "flaskCluster": {
        "Destinations": {
          "d1": { "Address": "http://127.0.0.1:5001/" }
        }
      }
    }
  }
}
```

**Important:** Adjust the port (`5001`) to match your Waitress configuration.

### Step 4: Publish YARP Gateway

```powershell
cd C:\Repos\JIT-Access-for-Data\IIS\YarpGateway
dotnet publish -c Release -o C:\inetpub\wwwroot\YarpGateway
```

---

## Part 3: Configure IIS for YARP Gateway

### Step 1: Create IIS Application Pool

1. Open IIS Manager
2. Right-click "Application Pools" → "Add Application Pool"
3. Configure:
   - **Name**: `YarpGatewayAppPool`
   - **.NET CLR Version**: `No Managed Code` (ASP.NET Core uses ANCM)
   - **Managed Pipeline Mode**: `Integrated`
4. Click "OK"

### Step 2: Configure Application Pool

1. Select `YarpGatewayAppPool`
2. Click "Advanced Settings"
3. Configure:
   - **Identity**: `ApplicationPoolIdentity` (or specific service account)
   - **Load User Profile**: `True`
   - **Start Mode**: `AlwaysRunning` (optional, for better performance)
4. Click "OK"

### Step 3: Create IIS Website

1. Right-click "Sites" → "Add Website"
2. Configure:
   - **Site name**: `YarpGateway` (or your preferred name)
   - **Application pool**: `YarpGatewayAppPool`
   - **Physical path**: `C:\inetpub\wwwroot\YarpGateway`
   - **Binding**:
     - Type: `https`
     - IP address: `All Unassigned` or specific IP
     - Port: `443` for HTTPS
     - Host name: `your-domain.com` (required)
3. Click "OK"

### Step 4: Enable Windows Authentication

1. Select your website (`YarpGateway`)
2. Double-click "Authentication"
3. Right-click "Anonymous Authentication" → **Disable**
4. Right-click "Windows Authentication" → **Enable**
5. Right-click "Windows Authentication" → "Advanced Settings"
6. Configure:
   - **Extended Protection**: `Off` (or `Accept` if your environment supports it)
   - **Enable Kernel-mode authentication**: `True` (recommended for performance)

### Step 5: Configure Provider Settings (Optional)

1. Select "Windows Authentication" → "Providers"
2. Ensure providers are in this order:
   - `Negotiate` (first)
   - `NTLM` (second)

### Step 6: Set Permissions

1. Right-click `C:\inetpub\YarpGateway` → "Properties" → "Security"
2. Add permissions for:
   - `IIS_IUSRS`: Read & Execute
   - `IIS AppPool\YarpGatewayAppPool`: Read & Execute

---

## Part 4: Configure Flask Application

### Step 1: Create wsgi.py

Create `flask_app/wsgi.py`:

```python
"""
WSGI entry point for Waitress
"""
from app import app

if __name__ == "__main__":
    from waitress import serve
    serve(app, host="127.0.0.1", port=5001, threads=8)
```

### Step 2: Verify Flask Auth Configuration

Ensure `flask_app/utils/auth.py` reads from `X-Remote-User` header:

```python
def get_windows_username():
    """
    Get the current Windows username from X-Remote-User header.
    This header is set by the YARP gateway from Windows Authentication.
    """
    return request.headers.get('X-Remote-User')
```

---

## Part 5: Configure Waitress as Windows Service using NSSM

NSSM (Non-Sucking Service Manager) is a tool for running applications as Windows services. It's more reliable than Python-based service wrappers.

### Step 1: Download and Install NSSM

1. Download NSSM from: https://nssm.cc/download
2. Extract the ZIP file
3. Copy `nssm.exe` (from the `win64` or `win32` folder) to a permanent location:
   ```powershell
   # Example: Copy to C:\Tools\nssm\nssm.exe
   mkdir C:\Tools\nssm
   copy nssm.exe C:\Tools\nssm\
   ```
4. Add NSSM to PATH (optional but recommended):
   - Add `C:\Tools\nssm` to your system PATH, or
   - Use full path when running NSSM commands

### Step 2: Determine Your Paths

Before installing the service, determine these paths:

- **Flask App Directory**: Where your `flask_app` folder is located
  - Example: `C:\Repos\JIT-Access-for-Data\flask_app`
- **Python Executable**: Path to your Python interpreter
  - If using virtual environment: `C:\Repos\JIT-Access-for-Data\.venv\Scripts\python.exe`
  - If using system Python: `C:\Python312\python.exe` (or wherever Python is installed)
- **Logs Directory**: Where to store service logs
  - Example: `C:\Repos\JIT-Access-for-Data\logs`

### Step 3: Create Logs Directory

```powershell
# Adjust path to match your project location
mkdir C:\Repos\JIT-Access-for-Data\logs
```

### Step 4: Install Waitress Service with NSSM

Run PowerShell as Administrator:

```powershell
# Set your paths (adjust these to match your installation)
$nssm = "C:\Tools\nssm\nssm.exe"  # Path to nssm.exe
$serviceName = "FlaskWaitress"
$pythonExe = "C:\Repos\JIT-Access-for-Data\.venv\Scripts\python.exe"  # Your Python executable
$appDir = "C:\Repos\JIT-Access-for-Data\flask_app"  # Flask app directory
$logDir = "C:\Repos\JIT-Access-for-Data\logs"  # Logs directory

# Install the service
& $nssm install $serviceName $pythonExe "-m waitress --host=127.0.0.1 --port=5001 wsgi:app"

# Set working directory (where wsgi.py is located)
& $nssm set $serviceName AppDirectory $appDir

# Set display name and description
& $nssm set $serviceName DisplayName "Flask Waitress Service"
& $nssm set $serviceName Description "Runs Flask application via Waitress WSGI server"

# Configure logging
& $nssm set $serviceName AppStdout "$logDir\stdout.log"
& $nssm set $serviceName AppStderr "$logDir\stderr.log"
& $nssm set $serviceName AppRotateFiles 1
& $nssm set $serviceName AppRotateOnline 1
& $nssm set $serviceName AppRotateSeconds 86400
& $nssm set $serviceName AppRotateBytes 10485760

# Configure service to restart on failure
& $nssm set $serviceName AppExit Default Restart
& $nssm set $serviceName AppRestartDelay 5000

# Set service to start automatically
& $nssm set $serviceName Start SERVICE_AUTO_START

# Set service account (optional - defaults to LocalSystem)
# If you need to use a specific account:
# & $nssm set $serviceName ObjectName "DOMAIN\ServiceAccount" "Password"
```

**Alternative: Manual Installation via GUI**

If you prefer a GUI:

1. Run Command Prompt as Administrator
2. Navigate to NSSM directory: `cd C:\Tools\nssm`
3. Run: `nssm install FlaskWaitress`
4. In the NSSM GUI:
   - **Path**: `C:\Repos\JIT-Access-for-Data\.venv\Scripts\python.exe`
   - **Startup directory**: `C:\Repos\JIT-Access-for-Data\flask_app`
   - **Arguments**: `-m waitress --host=127.0.0.1 --port=5001 wsgi:app`
5. Go to **Log on** tab → Set service account if needed
6. Go to **I/O** tab:
   - **Output (stdout)**: `C:\Repos\JIT-Access-for-Data\logs\stdout.log`
   - **Error (stderr)**: `C:\Repos\JIT-Access-for-Data\logs\stderr.log`
7. Go to **Exit actions** tab → Set to restart on failure
8. Click **Install service**

### Step 5: Start the Service

```powershell
# Using NSSM
& $nssm start FlaskWaitress

# Or using Windows Service commands
Start-Service FlaskWaitress
```

### Step 6: Verify Service Status

```powershell
Get-Service FlaskWaitress
```

Or check Windows Services (`services.msc`) for "Flask Waitress Service"

### Step 7: Verify Waitress is Running

```powershell
# Check if port 5001 is listening
netstat -an | findstr :5001

# Should show: TCP    127.0.0.1:5001    0.0.0.0:0    LISTENING
```

---

## Part 6: Testing and Verification

### Step 1: Test Waitress Service

1. Check if Waitress is listening:
   ```powershell
   netstat -an | findstr :5001
   ```
   Should show `127.0.0.1:5001` in LISTENING state

2. Test locally (from server):
   ```powershell
   Invoke-WebRequest -Uri "http://127.0.0.1:5001/" -UseDefaultCredentials
   ```

### Step 2: Test YARP Gateway

1. Access your IIS site: `http://your-server/` (or your configured hostname)
2. You should be prompted for Windows Authentication
3. After authentication, you should see your Flask application

### Step 3: Verify Headers (OPTIONAL)

Add a temporary debug endpoint to Flask to verify headers:

```python
@app.route('/debug/headers')
def debug_headers():
    return jsonify({
        'x_remote_user': request.headers.get('X-Remote-User'),
        'all_headers': dict(request.headers)
    })
```

Access: `http://your-server/debug/headers`

You should see `X-Remote-User` with your Windows username in format `DOMAIN\username`.

---

## Part 7: Troubleshooting

### Issue: YARP Gateway Not Starting

**Symptoms:**
- 502 Bad Gateway
- YARP site shows error

**Solutions:**
1. Check Event Viewer → Windows Logs → Application
2. Verify ASP.NET Core Hosting Bundle is installed
3. Check application pool is running
4. Verify `appsettings.json` is in `C:\inetpub\YarpGateway`
5. Check YARP logs: `C:\inetpub\YarpGateway\logs\` (if configured)

### Issue: Waitress Service Not Starting

**Symptoms:**
- Service shows "Stopped" or "Error"
- Flask app not accessible

**Solutions:**
1. Check NSSM service status:
   ```powershell
   C:\Tools\nssm\nssm.exe status FlaskWaitress
   ```
2. Check stdout/stderr logs:
   - `C:\Repos\JIT-Access-for-Data\logs\stdout.log`
   - `C:\Repos\JIT-Access-for-Data\logs\stderr.log`
3. Verify NSSM configuration:
   ```powershell
   C:\Tools\nssm\nssm.exe get FlaskWaitress AppDirectory
   C:\Tools\nssm\nssm.exe get FlaskWaitress AppParameters
   ```
4. Verify Python path is correct:
   ```powershell
   C:\Tools\nssm\nssm.exe get FlaskWaitress Application
   ```
5. Test manually (run from flask_app directory):
   ```powershell
   cd C:\Repos\JIT-Access-for-Data\flask_app
   C:\Repos\JIT-Access-for-Data\.venv\Scripts\python.exe -m waitress --host=127.0.0.1 --port=5001 wsgi:app
   ```
6. Check Windows Event Viewer → Application logs for NSSM errors
7. Verify file permissions on Flask app directory
8. Check if port 5001 is already in use:
   ```powershell
   netstat -an | findstr :5001
   ```

### Issue: X-Remote-User Header Not Present

**Symptoms:**
- Flask app shows no user
- Debug endpoint shows `X-Remote-User: None`

**Solutions:**
1. Verify Windows Authentication is enabled in IIS
2. Verify Anonymous Authentication is disabled
3. Check YARP `Program.cs` - ensure transform is configured
4. Verify user is accessing from domain-joined machine
5. Check browser settings (some browsers need configuration for Windows Auth)

### Issue: Connection Refused (502 Bad Gateway)

**Symptoms:**
- YARP returns 502 Bad Gateway
- Cannot connect to Flask

**Solutions:**
1. Verify Waitress service is running:
   ```powershell
   Get-Service FlaskWaitress
   C:\Tools\nssm\nssm.exe status FlaskWaitress
   ```
2. Check if port 5001 is listening:
   ```powershell
   netstat -an | findstr :5001
   ```
3. Verify `appsettings.json` port matches Waitress port
4. Check Windows Firewall (should allow localhost connections)
5. Test Waitress directly:
   ```powershell
   Invoke-WebRequest -Uri "http://127.0.0.1:5001/" -UseDefaultCredentials
   ```
6. Check NSSM logs for startup errors:
   ```powershell
   Get-Content C:\Repos\JIT-Access-for-Data\logs\stderr.log -Tail 20
   ```

### Issue: Service Crashes Repeatedly

**Symptoms:**
- Service starts then stops immediately
- Event log shows errors

**Solutions:**
1. Check stderr.log for Python errors:
   ```powershell
   Get-Content C:\Repos\JIT-Access-for-Data\logs\stderr.log -Tail 50
   ```
2. Check NSSM exit code:
   ```powershell
   C:\Tools\nssm\nssm.exe status FlaskWaitress
   ```
3. Verify all dependencies are installed in virtual environment:
   ```powershell
   C:\Repos\JIT-Access-for-Data\.venv\Scripts\python.exe -m pip list
   ```
4. Check database connection (if Flask tries to connect on startup)
5. Verify file permissions on Flask app directory
6. Verify NSSM paths are correct:
   ```powershell
   C:\Tools\nssm\nssm.exe get FlaskWaitress Application
   C:\Tools\nssm\nssm.exe get FlaskWaitress AppDirectory
   ```
7. Test Flask app manually first:
   ```powershell
   cd C:\Repos\JIT-Access-for-Data\flask_app
   C:\Repos\JIT-Access-for-Data\.venv\Scripts\python.exe wsgi.py
   ```
8. Check if virtual environment is activated correctly in NSSM (may need full path to Python)

---

## Part 8: Service Management

### Start Service
```powershell
# Using NSSM
C:\Tools\nssm\nssm.exe start FlaskWaitress

# Or using Windows Service commands
Start-Service FlaskWaitress
```

### Stop Service
```powershell
# Using NSSM
C:\Tools\nssm\nssm.exe stop FlaskWaitress

# Or using Windows Service commands
Stop-Service FlaskWaitress
```

### Restart Service
```powershell
# Using NSSM
C:\Tools\nssm\nssm.exe restart FlaskWaitress

# Or using Windows Service commands
Restart-Service FlaskWaitress
```

### Remove Service
```powershell
# Stop the service first
C:\Tools\nssm\nssm.exe stop FlaskWaitress

# Remove the service
C:\Tools\nssm\nssm.exe remove FlaskWaitress confirm
```

### Check Service Status
```powershell
# Using NSSM (shows detailed status)
C:\Tools\nssm\nssm.exe status FlaskWaitress

# Or using Windows Service commands
Get-Service FlaskWaitress
```

### View Service Configuration
```powershell
# View all NSSM settings
C:\Tools\nssm\nssm.exe get FlaskWaitress Application
C:\Tools\nssm\nssm.exe get FlaskWaitress AppDirectory
C:\Tools\nssm\nssm.exe get FlaskWaitress AppParameters

# Or use Windows Services Manager (services.msc) for basic management
```

### Edit Service Configuration
```powershell
# Open NSSM GUI to edit settings
C:\Tools\nssm\nssm.exe edit FlaskWaitress
```

Or use Windows Services Manager (`services.msc`) for basic operations

---

## Part 9: Production Checklist

- [ ] .NET SDK installed (LTS version)
- [ ] ASP.NET Core Hosting Bundle installed (matching SDK version)
- [ ] Python virtual environment created with all dependencies
- [ ] YARP Gateway published to `C:\inetpub\wwwroot\YarpGateway`
- [ ] IIS Application Pool created and configured
- [ ] IIS Website created with Windows Authentication enabled
- [ ] Anonymous Authentication disabled
- [ ] NSSM installed
- [ ] Waitress service installed and configured via NSSM
- [ ] Service recovery configured (auto-restart on failure)
- [ ] Logs directory created and accessible
- [ ] File permissions configured
- [ ] `appsettings.json` port matches Waitress port
- [ ] Flask `wsgi.py` configured correctly
- [ ] Flask `auth.py` reads `X-Remote-User` header
- [ ] Tested end-to-end authentication flow
- [ ] HTTPS configured (if using SSL)
- [ ] Firewall rules configured (if needed)
- [ ] Monitoring/logging configured

---

## Part 10: Security Best Practices

1. **Use HTTPS**: Configure SSL certificate for production
2. **Service Account**: Use dedicated service account for app pool (not ApplicationPoolIdentity)
3. **File Permissions**: Restrict file system permissions to minimum required
4. **Network Isolation**: Waitress should only listen on `127.0.0.1` (localhost)
5. **Firewall**: Ensure Windows Firewall blocks external access to port 5001
6. **Logging**: Enable application logging and monitor for security events
7. **Updates**: Keep .NET SDK, ASP.NET Core Hosting Bundle, and Python updated
8. **Headers**: YARP removes client-supplied `X-Remote-User` to prevent spoofing

---

## Additional Resources

- [YARP Documentation](https://microsoft.github.io/reverse-proxy/)
- [Waitress Documentation](https://docs.pylonsproject.org/projects/waitress/)
- [ASP.NET Core Hosting Bundle](https://dotnet.microsoft.com/download/dotnet)
- [NSSM Documentation](https://nssm.cc/usage)
- [NSSM Download](https://nssm.cc/download)

---

## Support

If you encounter issues:

1. **Check Waitress logs**: `C:\Repos\JIT-Access-for-Data\logs\stdout.log` and `stderr.log`
2. **Check Windows Event Viewer**: Application logs for service errors
3. **Check IIS logs**: `C:\inetpub\logs\LogFiles\W3SVC*\`
4. **Verify YARP configuration**: Check `appsettings.json` and `Program.cs`
5. **Test components individually**: Test Waitress directly, then YARP, then full stack
