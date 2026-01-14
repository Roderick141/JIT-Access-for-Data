"""
Authentication utilities for JIT Access Framework
Uses Windows Authentication for user identification, SQL Auth for database connection
"""
import os
import pyodbc
from flask import session, request, redirect, url_for, g
from functools import wraps
from .db import get_db_connection, execute_query

def get_windows_username():
    """
    Get the current Windows username
    In production with IIS/Windows Auth, this would come from request headers
    For development, uses environment variables
    """
    # Try to get from environment (development)
    windows_user = os.environ.get('USERNAME') or os.environ.get('USER') or None
    
    # In production, you might get this from request headers if using IIS with Windows Auth:
    # windows_user = request.headers.get('REMOTE_USER') or request.headers.get('AUTH_USER')
    
    return windows_user

def get_current_user():
    """
    Get current user information from database
    User must exist in jit.Users table (no auto-creation)
    Returns user dictionary or None if not found
    """
    try:
        windows_username = get_windows_username()
        
        # Validate that we have a string username
        if not windows_username or not isinstance(windows_username, str) or not windows_username.strip():
            return None
        
        # Ensure it's a string and strip whitespace
        windows_username = str(windows_username).strip()
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Try to find user by login name (exact match or domain\username format)
        # Users need to be created manually or via AD sync
        # Try multiple patterns: exact match, domain\username, just username
        search_pattern = f'%\\{windows_username}'
        
        cursor.execute("""
            SELECT UserId, LoginName, GivenName, Surname, DisplayName, 
                   Email, Division, Department, JobTitle, SeniorityLevel, 
                   IsAdmin, IsApprover, IsDataSteward, IsActive
            FROM jit.Users 
            WHERE (LoginName = ? OR LoginName LIKE ? OR LoginName = ?)
            AND IsActive = 1
        """, windows_username, search_pattern, windows_username)
        
        row = cursor.fetchone()
        if row:
            columns = [column[0] for column in cursor.description]
            user_dict = dict(zip(columns, row))
            cursor.close()
            return user_dict
        
        cursor.close()
        return None
        
    except Exception as e:
        print(f"Error getting current user: {e}")
        import traceback
        traceback.print_exc()
        return None

def is_approver(user_id):
    """
    Check if user has the capability to approve requests
    Returns True if user is admin OR IsApprover column is set to 1
    """
    if not user_id:
        return False
        
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Check if user is admin or has IsApprover flag set
        cursor.execute("""
            SELECT IsAdmin, IsApprover
            FROM jit.Users 
            WHERE UserId = ? AND IsActive = 1
        """, user_id)
        
        result = cursor.fetchone()
        cursor.close()
        
        if result:
            is_admin = result[0]
            is_approver = result[1]
            return bool(is_admin) or bool(is_approver)
        return False
        
    except Exception as e:
        print(f"Error checking approver status: {e}")
        return False

def is_admin(user_id):
    """
    Check if user is an admin
    Checks IsAdmin column in jit.Users table
    """
    if not user_id:
        return False
        
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT IsAdmin 
            FROM jit.Users 
            WHERE UserId = ? AND IsActive = 1
        """, user_id)
        
        result = cursor.fetchone()
        cursor.close()
        
        if result:
            return bool(result[0])
        return False
        
    except Exception as e:
        print(f"Error checking admin status: {e}")
        return False

def login_required(f):
    """Decorator to require user to be logged in"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        user = get_current_user()
        if user is None:
            from flask import flash
            flash('User not found. Please contact your administrator to create your account.', 'error')
            return redirect(url_for('login'))
        session['user'] = user
        return f(*args, **kwargs)
    return decorated_function

def approver_required(f):
    """Decorator to require approver access"""
    @wraps(f)
    @login_required
    def decorated_function(*args, **kwargs):
        user = session.get('user')
        if not user:
            return redirect(url_for('login'))
        
        # Check if user is an approver
        if not is_approver(user.get('UserId')):
            from flask import flash
            flash('You do not have permission to access this page. Approver access required.', 'error')
            return redirect(url_for('user_dashboard'))
        
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """Decorator to require admin access"""
    @wraps(f)
    @login_required
    def decorated_function(*args, **kwargs):
        user = session.get('user')
        if not user:
            return redirect(url_for('login'))
        
        # Check if user is an admin
        if not is_admin(user.get('UserId')):
            from flask import flash
            flash('You do not have permission to access this page. Administrator access required.', 'error')
            return redirect(url_for('user_dashboard'))
        
        return f(*args, **kwargs)
    return decorated_function
