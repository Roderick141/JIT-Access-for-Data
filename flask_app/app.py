"""
JIT Access Framework - Flask Application
Main application file
"""
from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
from config import Config
from utils.db import get_db_connection, close_db, execute_procedure, execute_query
from utils.auth import get_current_user, login_required, admin_required, approver_required, is_approver, is_admin
import os
import mimetypes

app = Flask(__name__)
app.config.from_object(Config)

# Ensure CSS files are served with correct MIME type for Edge compatibility
mimetypes.add_type('text/css', '.css')

# Template filter to convert minutes to days
@app.template_filter('minutes_to_days')
def minutes_to_days_filter(minutes):
    """Convert minutes to days, rounding to 1 decimal place"""
    if minutes is None:
        return 0
    return round(minutes / 1440, 1)

# Register close_db to be called when request ends
app.teardown_appcontext(close_db)

# Add response headers for Edge compatibility
@app.after_request
def add_edge_headers(response):
    """Add headers to help Edge properly load CSS and other static files"""
    # Check if this is a CSS file request
    is_css_file = request.path.endswith('.css') or '/css/' in request.path
    
    # Ensure CSS files have correct Content-Type with charset
    if is_css_file:
        response.headers['Content-Type'] = 'text/css; charset=utf-8'
    
    # Add headers to prevent MIME type sniffing (Edge security feature)
    # This helps Edge trust the Content-Type header
    if 'X-Content-Type-Options' not in response.headers:
        response.headers['X-Content-Type-Options'] = 'nosniff'
    
    # Ensure proper cache headers for static files
    if '/static/' in request.path:
        if 'Cache-Control' not in response.headers:
            response.headers['Cache-Control'] = 'public, max-age=3600'
    
    return response

@app.route('/')
def index():
    """Redirect to dashboard"""
    user = get_current_user()
    if user:
        # Add role flags to user dict for template use
        user['IsApprover'] = is_approver(user.get('UserId'))
        user['IsAdmin'] = is_admin(user.get('UserId'))
        session['user'] = user
        return redirect(url_for('user_dashboard'))
    return redirect(url_for('login'))

@app.route('/login')
def login():
    """Login page (Windows Auth - auto-redirect if authenticated)"""
    user = get_current_user()
    if user:
        # Add role flags to user dict for template use
        user['IsApprover'] = is_approver(user.get('UserId'))
        user['IsAdmin'] = is_admin(user.get('UserId'))
        session['user'] = user
        return redirect(url_for('user_dashboard'))
    return render_template('login.html')

# ==================== USER ROUTES ====================

@app.route('/user/dashboard')
@login_required
def user_dashboard():
    """User dashboard - view active grants and expiry dates"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    # Ensure role flags are set
    if 'IsApprover' not in user:
        user['IsApprover'] = is_approver(user.get('UserId'))
    if 'IsAdmin' not in user:
        user['IsAdmin'] = is_admin(user.get('UserId'))
    session['user'] = user
    
    try:
        # Get active grants for user
        grants = execute_procedure('jit.sp_Grant_ListActiveForUser', {'UserId': user['UserId']})
        
        # Get pending requests
        requests = execute_procedure('jit.sp_Request_ListForUser', {'UserId': user['UserId']})
        
        return render_template('user/dashboard.html', 
                             user=user, 
                             grants=grants or [], 
                             requests=requests or [])
    except Exception as e:
        flash(f'Error loading dashboard: {str(e)}', 'error')
        return render_template('user/dashboard.html', user=user, grants=[], requests=[])

@app.route('/user/request', methods=['GET', 'POST'])
@login_required
def user_request():
    """Request access form"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    if request.method == 'POST':
        try:
            # Get multiple role IDs from form (can be list or single value)
            role_ids_raw = request.form.getlist('role_id')
            if not role_ids_raw:
                flash('Please select at least one role', 'error')
                roles = execute_procedure('jit.sp_Role_ListRequestable', {'UserId': user['UserId']})
                return render_template('user/request.html', user=user, roles=roles or [])
            
            # Convert to comma-separated string for stored procedure
            role_ids = ','.join(str(int(rid)) for rid in role_ids_raw if rid.strip())
            
            if not role_ids:
                flash('Please select at least one valid role', 'error')
                roles = execute_procedure('jit.sp_Role_ListRequestable', {'UserId': user['UserId']})
                return render_template('user/request.html', user=user, roles=roles or [])
            
            duration_days = int(request.form.get('duration_days'))
            # Convert days to minutes (1 day = 1440 minutes)
            duration_minutes = duration_days * 1440
            justification = request.form.get('justification', '')
            ticket_ref = request.form.get('ticket_ref', '').strip()  # Trim whitespace
            
            # Execute procedure that doesn't return results (fetch=False)
            execute_procedure('jit.sp_Request_Create', {
                'UserId': user['UserId'],
                'RoleIds': role_ids,  # Comma-separated string of role IDs
                'RequestedDurationMinutes': duration_minutes,
                'Justification': justification,
                'TicketRef': ticket_ref if ticket_ref else None
            }, fetch=False)
            
            role_count = len(role_ids_raw)
            flash(f'Request submitted successfully for {role_count} role(s)!', 'success')
            return redirect(url_for('user_dashboard'))
        except Exception as e:
            flash(f'Error submitting request: {str(e)}', 'error')
    
    # Get requestable roles
    try:
        roles = execute_procedure('jit.sp_Role_ListRequestable', {'UserId': user['UserId']})
    except Exception as e:
        roles = []
        flash(f'Error loading roles: {str(e)}', 'error')
    
    return render_template('user/request.html', user=user, roles=roles or [])

@app.route('/user/history')
@login_required
def user_history():
    """Request history"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        requests = execute_procedure('jit.sp_Request_ListForUser', {'UserId': user['UserId']})
    except Exception as e:
        requests = []
        flash(f'Error loading history: {str(e)}', 'error')
    
    return render_template('user/history.html', user=user, requests=requests or [])

@app.route('/user/cancel/<int:request_id>')
@login_required
def user_cancel(request_id):
    """Cancel pending request"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        execute_procedure('jit.sp_Request_Cancel', {'RequestId': request_id, 'UserId': user['UserId']}, fetch=False)
        flash('Request cancelled successfully', 'success')
    except Exception as e:
        flash(f'Error cancelling request: {str(e)}', 'error')
    
    return redirect(url_for('user_dashboard'))

# ==================== APPROVER ROUTES ====================

@app.route('/approver/dashboard')
@approver_required
def approver_dashboard():
    """Approver dashboard - pending approvals queue"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    # Ensure role flags are refreshed
    user['IsApprover'] = is_approver(user.get('UserId'))
    user['IsAdmin'] = is_admin(user.get('UserId'))
    session['user'] = user
    
    try:
        requests = execute_procedure('jit.sp_Request_ListPendingForApprover', {'ApproverUserId': user['UserId']})
    except Exception as e:
        requests = []
        flash(f'Error loading approvals: {str(e)}', 'error')
    
    return render_template('approver/dashboard.html', user=user, requests=requests or [])

@app.route('/approver/request/<int:request_id>')
@approver_required
def approver_request_detail(request_id):
    """Review request details"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        # Get request details
        request_data = execute_query(
            """SELECT 
                r.RequestId,
                r.UserId,
                r.RequestedDurationMinutes,
                r.Justification,
                r.TicketRef,
                r.Status,
                r.UserDeptSnapshot,
                r.UserTitleSnapshot,
                r.CreatedUtc,
                r.UpdatedUtc,
                u.DisplayName AS RequesterName,
                u.LoginName AS RequesterLoginName,
                u.Department AS RequesterDepartment,
                u.Division AS RequesterDivision,
                u.SeniorityLevel AS RequesterSeniority
            FROM jit.Requests r
            INNER JOIN jit.Users u ON r.UserId = u.UserId
            WHERE r.RequestId = ?""",
            [request_id]
        )
        
        request_data = request_data[0] if request_data else None
        
        if not request_data:
            flash('Request not found', 'error')
            return redirect(url_for('approver_dashboard'))
        
        # Get all roles for this request
        roles = execute_procedure('jit.sp_Request_GetRoles', {'RequestId': request_id})
        request_data['Roles'] = roles if roles else []
        
        return render_template('approver/approve.html', user=user, request_data=request_data)
    except Exception as e:
        flash(f'Error loading request: {str(e)}', 'error')
        return redirect(url_for('approver_dashboard'))

@app.route('/approver/approve/<int:request_id>', methods=['POST'])
@approver_required
def approver_approve(request_id):
    """Approve request"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        # Permission check is done in stored procedure, but we can add UI-level check for better UX
        # The stored procedure will throw an error if permission is denied
        
        comment = request.form.get('comment', '')
        execute_procedure('jit.sp_Request_Approve', {
            'RequestId': request_id,
            'ApproverUserId': user['UserId'],
            'DecisionComment': comment
        }, fetch=False)
        flash('Request approved successfully', 'success')
    except Exception as e:
        flash(f'Error approving request: {str(e)}', 'error')
    
    return redirect(url_for('approver_dashboard'))

@app.route('/approver/deny/<int:request_id>', methods=['POST'])
@approver_required
def approver_deny(request_id):
    """Deny request"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        # Permission check is done in stored procedure, but we can add UI-level check for better UX
        # The stored procedure will throw an error if permission is denied
        
        comment = request.form.get('comment', '')
        execute_procedure('jit.sp_Request_Deny', {
            'RequestId': request_id,
            'ApproverUserId': user['UserId'],
            'DecisionComment': comment
        }, fetch=False)
        flash('Request denied', 'info')
    except Exception as e:
        flash(f'Error denying request: {str(e)}', 'error')
    
    return redirect(url_for('approver_dashboard'))

# ==================== ADMIN ROUTES ====================

@app.route('/admin/dashboard')
@admin_required
def admin_dashboard():
    """Admin dashboard"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    return render_template('admin/dashboard.html', user=user)

@app.route('/admin/roles')
@admin_required
def admin_roles():
    """Manage role catalog"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        roles = execute_query("SELECT * FROM jit.Roles ORDER BY RoleName")
    except Exception as e:
        roles = []
        flash(f'Error loading roles: {str(e)}', 'error')
    
    return render_template('admin/roles.html', user=user, roles=roles or [])

@app.route('/admin/teams')
@admin_required
def admin_teams():
    """Manage teams"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        teams = execute_query("SELECT * FROM jit.Teams WHERE IsActive = 1 ORDER BY TeamName")
    except Exception as e:
        teams = []
        flash(f'Error loading teams: {str(e)}', 'error')
    
    return render_template('admin/teams.html', user=user, teams=teams or [])

@app.route('/admin/eligibility')
@admin_required
def admin_eligibility():
    """Manage eligibility rules"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        rules = execute_query("""
            SELECT rer.*, r.RoleName 
            FROM jit.Role_Eligibility_Rules rer
            INNER JOIN jit.Roles r ON rer.RoleId = r.RoleId
            ORDER BY r.RoleName, rer.Priority DESC
        """)
    except Exception as e:
        rules = []
        flash(f'Error loading eligibility rules: {str(e)}', 'error')
    
    return render_template('admin/eligibility.html', user=user, rules=rules or [])

@app.route('/admin/users')
@admin_required
def admin_users():
    """User list (AD sync status)"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        users = execute_query("SELECT * FROM jit.Users ORDER BY LoginName")
    except Exception as e:
        users = []
        flash(f'Error loading users: {str(e)}', 'error')
    
    return render_template('admin/users.html', user=user, users=users or [])

@app.route('/admin/reports')
@admin_required
def admin_reports():
    """Audit reports and drift detection"""
    user = session.get('user')
    if not user:
        return redirect(url_for('login'))
    
    try:
        # Get recent audit logs
        audit_logs = execute_query("""
            SELECT TOP 100 * FROM jit.AuditLog 
            ORDER BY EventUtc DESC
        """)
        
        # Get active grants summary
        active_grants = execute_query("""
            SELECT COUNT(*) as Count FROM jit.Grants WHERE Status = 'Active'
        """)
    except Exception as e:
        audit_logs = []
        active_grants = [{'Count': 0}]
        flash(f'Error loading reports: {str(e)}', 'error')
    
    return render_template('admin/reports.html', 
                         user=user, 
                         audit_logs=audit_logs or [],
                         active_grants=active_grants[0] if active_grants else {'Count': 0})

@app.route('/debug/auth')
def debug_auth():
    """Debug endpoint to check authentication headers and token processing"""
    from flask import jsonify
    from utils.auth import get_windows_username
    
    headers = dict(request.headers)
    windows_user = get_windows_username()
    
    return jsonify({
        'headers': headers,
        'windows_username': windows_user,
        'x_iis_token': request.headers.get('X-IIS-WindowsAuthToken') or request.headers.get('HTTP_X_IIS_WINDOWSAUTHTOKEN'),
        'all_headers_keys': list(request.headers.keys())
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

