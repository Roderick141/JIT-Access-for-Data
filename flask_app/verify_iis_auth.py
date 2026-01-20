"""
Simple Flask app to verify Windows Authentication headers from IIS
This script displays all request headers and specifically checks for Windows user information
"""
from flask import Flask, request, jsonify, render_template_string
import os

app = Flask(__name__)

# HTML template for displaying headers
HEADERS_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>IIS Windows Auth Verification</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 40px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #0078d4;
            padding-bottom: 10px;
        }
        h2 {
            color: #0078d4;
            margin-top: 30px;
        }
        .status {
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            font-weight: bold;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .warning {
            background-color: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }
        .error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078d4;
            color: white;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .header-name {
            font-weight: bold;
            color: #0078d4;
        }
        .code-block {
            background-color: #f4f4f4;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #0078d4;
            font-family: 'Courier New', monospace;
            margin: 10px 0;
            overflow-x: auto;
        }
        .info-box {
            background-color: #e7f3ff;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #0078d4;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 IIS Windows Authentication Verification</h1>
        
        <h2>Authentication Status</h2>
        {{ auth_status|safe }}
        
        <h2>Windows User Information</h2>
        <div class="info-box">
            <strong>REMOTE_USER:</strong> {{ remote_user }}<br>
            <strong>AUTH_USER:</strong> {{ auth_user }}<br>
            <strong>LOGON_USER:</strong> {{ logon_user }}<br>
            <strong>HTTP_X_FORWARDED_USER:</strong> {{ forwarded_user }}<br>
            <strong>HTTP_X_REMOTE_USER:</strong> {{ http_remote_user }}<br>
            <strong>HTTP_X_ORIGINAL_URL:</strong> {{ original_url }}<br>
        </div>
        
        <h2>All Request Headers</h2>
        <table>
            <thead>
                <tr>
                    <th>Header Name</th>
                    <th>Value</th>
                </tr>
            </thead>
            <tbody>
                {% for header, value in headers.items() %}
                <tr>
                    <td class="header-name">{{ header }}</td>
                    <td>{{ value }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
        
        <h2>Environment Variables</h2>
        <div class="code-block">
            <strong>USERNAME:</strong> {{ env_username }}<br>
            <strong>USER:</strong> {{ env_user }}<br>
            <strong>USERPROFILE:</strong> {{ env_userprofile }}<br>
        </div>
        
        <h2>JSON API Endpoint</h2>
        <p>You can also access this information as JSON at: <a href="/api/headers">/api/headers</a></p>
    </div>
</body>
</html>
"""

@app.route('/')
def index():
    """Display all headers and Windows auth information"""
    # Get Windows authentication headers
    remote_user = request.headers.get('REMOTE_USER', 'Not set')
    auth_user = request.headers.get('AUTH_USER', 'Not set')
    logon_user = request.headers.get('LOGON_USER', 'Not set')
    forwarded_user = request.headers.get('HTTP_X_FORWARDED_USER', 'Not set')
    http_remote_user = request.headers.get('HTTP_X_REMOTE_USER', 'Not set')
    original_url = request.headers.get('HTTP_X_ORIGINAL_URL', 'Not set')
    
    # Determine authentication status
    windows_user = remote_user or auth_user or logon_user or forwarded_user or http_remote_user
    
    if windows_user and windows_user != 'Not set':
        auth_status = '''
        <div class="status success">
            ✅ Windows Authentication is WORKING!<br>
            Detected Windows User: <strong>{}</strong>
        </div>
        '''.format(windows_user)
    else:
        auth_status = '''
        <div class="status error">
            ❌ Windows Authentication NOT detected!<br>
            No Windows user headers found. Check IIS configuration.
        </div>
        '''
    
    # Get all headers
    all_headers = dict(request.headers)
    
    # Get environment variables
    env_username = os.environ.get('USERNAME', 'Not set')
    env_user = os.environ.get('USER', 'Not set')
    env_userprofile = os.environ.get('USERPROFILE', 'Not set')
    
    return render_template_string(
        HEADERS_TEMPLATE,
        auth_status=auth_status,
        remote_user=remote_user,
        auth_user=auth_user,
        logon_user=logon_user,
        forwarded_user=forwarded_user,
        http_remote_user=http_remote_user,
        original_url=original_url,
        headers=all_headers,
        env_username=env_username,
        env_user=env_user,
        env_userprofile=env_userprofile
    )

@app.route('/api/headers')
def api_headers():
    """JSON API endpoint to get all headers"""
    return jsonify({
        'windows_auth': {
            'REMOTE_USER': request.headers.get('REMOTE_USER'),
            'AUTH_USER': request.headers.get('AUTH_USER'),
            'LOGON_USER': request.headers.get('LOGON_USER'),
            'HTTP_X_FORWARDED_USER': request.headers.get('HTTP_X_FORWARDED_USER'),
            'HTTP_X_REMOTE_USER': request.headers.get('HTTP_X_REMOTE_USER'),
            'HTTP_X_ORIGINAL_URL': request.headers.get('HTTP_X_ORIGINAL_URL'),
        },
        'detected_user': (
            request.headers.get('REMOTE_USER') or 
            request.headers.get('AUTH_USER') or 
            request.headers.get('LOGON_USER') or 
            request.headers.get('HTTP_X_FORWARDED_USER') or 
            request.headers.get('HTTP_X_REMOTE_USER')
        ),
        'all_headers': dict(request.headers),
        'environment': {
            'USERNAME': os.environ.get('USERNAME'),
            'USER': os.environ.get('USER'),
            'USERPROFILE': os.environ.get('USERPROFILE'),
        }
    })

if __name__ == '__main__':
    print("=" * 60)
    print("IIS Windows Authentication Verification Tool")
    print("=" * 60)
    print("\nAccess the verification page at: http://localhost:5000/")
    print("JSON API endpoint: http://localhost:5000/api/headers")
    print("\nNote: This is for testing. In production, run via IIS.")
    print("=" * 60)
    app.run(debug=True, host='0.0.0.0', port=5000)
