"""
Authentication utilities for JIT Access Framework
Uses Windows Authentication (integrated security)
"""
import os
from flask import session, request, redirect, url_for
from functools import wraps
from .db import execute_procedure

def get_current_user():
    """
    Get current user information from database
    Returns user dictionary or None if not found
    """
    try:
        result = execute_procedure('jit.sp_User_ResolveCurrentUser', fetch=False)
        
        # For output parameters, we need to handle differently
        # This is a simplified version - in production, use proper output parameter handling
        conn = request.environ.get('db_connection')
        if conn:
            cursor = conn.cursor()
            cursor.execute("EXEC jit.sp_User_ResolveCurrentUser")
            
            # Get output parameters or result set
            # This is simplified - actual implementation depends on procedure design
            pass
        
        # Alternative: Query user directly by login
        login_name = os.environ.get('USERNAME') or os.environ.get('USER') or 'SYSTEM'
        result = execute_procedure('jit.sp_User_GetByLogin', {'LoginName': login_name})
        
        if result and len(result) > 0:
            return result[0]
        return None
    except Exception as e:
        print(f"Error getting current user: {e}")
        return None

def login_required(f):
    """Decorator to require user to be logged in"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        user = get_current_user()
        if user is None:
            return redirect(url_for('login'))
        session['user'] = user
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """Decorator to require admin access (placeholder - implement actual admin check)"""
    @wraps(f)
    @login_required
    def decorated_function(*args, **kwargs):
        # TODO: Implement actual admin role check
        # For now, allow if user exists
        return f(*args, **kwargs)
    return decorated_function

def approver_required(f):
    """Decorator to require approver access (placeholder - implement actual approver check)"""
    @wraps(f)
    @login_required
    def decorated_function(*args, **kwargs):
        # TODO: Implement actual approver role check
        return f(*args, **kwargs)
    return decorated_function

