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
3. **Waitress** - Python WSGI server running Flask as a Windows service
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

## Part 5: Configure Waitress as Windows Service

### Step 1: Update waitress_service.py Paths

Update `IIS/WebServer/waitress_service.py` with your actual paths:

```python
# Update these paths to match your deployment
app_dir = r"C:\apps\flaskapp"  # Your Flask app directory
python_exe = r"C:\apps\flaskapp\.venv\Scripts\python.exe"  # Your Python executable
```

### Step 2: Create Logs Directory

```powershell
mkdir C:\apps\flaskapp\logs
```

### Step 3: Install Waitress Service

Run PowerShell as Administrator:

```powershell
cd C:\apps\flaskapp
C:\apps\flaskapp\.venv\Scripts\python.exe waitress_service.py install
```

### Step 4: Configure Service Recovery

Configure the service to restart automatically on failure:

```powershell
sc failure FlaskWaitress reset= 86400 actions= restart/5000/restart/5000/restart/5000
```

This configures:
- Reset failure count daily (`reset=86400`)
- Restart after 5 seconds on failure (3 attempts)

### Step 5: Start the Service

```powershell
C:\apps\flaskapp\.venv\Scripts\python.exe waitress_service.py start
```

### Step 6: Verify Service Status

```powershell
Get-Service FlaskWaitress
```

Or check Windows Services (services.msc) for "Flask Waitress Service"

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
1. Check service logs:
   ```powershell
   Get-EventLog -LogName Application -Source FlaskWaitress -Newest 10
   ```
2. Check stdout/stderr logs:
   - `C:\apps\flaskapp\logs\stdout.log`
   - `C:\apps\flaskapp\logs\stderr.log`
3. Verify Python path in `waitress_service.py` is correct
4. Verify Flask app path is correct
5. Test manually:
   ```powershell
   cd C:\apps\flaskapp
   .venv\Scripts\python.exe -m waitress --host=127.0.0.1 --port=5001 wsgi:app
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
   ```
2. Check if port 5001 is listening:
   ```powershell
   netstat -an | findstr :5001
   ```
3. Verify `appsettings.json` port matches Waitress port
4. Check Windows Firewall (should allow localhost connections)
5. Test Waitress directly:
   ```powershell
   curl http://127.0.0.1:5001/
   ```

### Issue: Service Crashes Repeatedly

**Symptoms:**
- Service starts then stops immediately
- Event log shows errors

**Solutions:**
1. Check stderr.log for Python errors
2. Verify all dependencies are installed in virtual environment
3. Check database connection (if Flask tries to connect on startup)
4. Verify file permissions on Flask app directory
5. Test Flask app manually first:
   ```powershell
   cd C:\apps\flaskapp
   .venv\Scripts\python.exe wsgi.py
   ```

---

## Part 8: Service Management

### Start Service
```powershell
C:\apps\flaskapp\.venv\Scripts\python.exe waitress_service.py start
```

### Stop Service
```powershell
C:\apps\flaskapp\.venv\Scripts\python.exe waitress_service.py stop
```

### Restart Service
```powershell
C:\apps\flaskapp\.venv\Scripts\python.exe waitress_service.py stop
C:\apps\flaskapp\.venv\Scripts\python.exe waitress_service.py start
```

### Remove Service
```powershell
C:\apps\flaskapp\.venv\Scripts\python.exe waitress_service.py remove
```

### Check Service Status
```powershell
Get-Service FlaskWaitress
```

Or use Windows Services Manager (`services.msc`)

---

## Part 9: Production Checklist

- [ ] .NET SDK installed (LTS version)
- [ ] ASP.NET Core Hosting Bundle installed (matching SDK version)
- [ ] Python virtual environment created with all dependencies
- [ ] YARP Gateway published to `C:\inetpub\YarpGateway`
- [ ] IIS Application Pool created and configured
- [ ] IIS Website created with Windows Authentication enabled
- [ ] Anonymous Authentication disabled
- [ ] Waitress service installed and configured
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
- [Windows Service with Python](https://pypi.org/project/pywin32/)

---

## Support

If you encounter issues:

1. **Check Waitress logs**: `C:\apps\flaskapp\logs\stdout.log` and `stderr.log`
2. **Check Windows Event Viewer**: Application logs for service errors
3. **Check IIS logs**: `C:\inetpub\logs\LogFiles\W3SVC*\`
4. **Verify YARP configuration**: Check `appsettings.json` and `Program.cs`
5. **Test components individually**: Test Waitress directly, then YARP, then full stack
