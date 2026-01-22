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
    Get the current Windows username from Windows Authentication Token.
    
    When HttpPlatformHandler has forwardWindowsAuthToken="true", IIS forwards
    the Windows authentication token in the thread context. The token is accessed
    via OpenThreadToken rather than using the handle from the header.
    
    Returns:
        str: Windows username in format 'DOMAIN\username' or 'username', or None if not found
    """
    import logging
    logger = logging.getLogger(__name__)
    
    # Get the Windows Auth Token from header (for verification/debugging)
    auth_token_hex = (
        request.headers.get('X-IIS-WindowsAuthToken') or
        request.headers.get('HTTP_X_IIS_WINDOWSAUTHTOKEN') or
        request.headers.get('X-IIS-WINDOWSAUTHTOKEN')
    )
    
    if not auth_token_hex:
        all_headers = list(request.headers.keys())
        print(f"DEBUG: X-IIS-WindowsAuthToken header not found. Available headers: {all_headers}")
        if logger.isEnabledFor(logging.DEBUG):
            logger.debug("X-IIS-WindowsAuthToken header not found")
            logger.debug(f"Available headers: {all_headers}")
        return None
    
    try:
        import win32security
        import win32api
        import win32con
        
        # Method 1: Use the thread token (HttpPlatformHandler sets it in thread context)
        # This is the most reliable method when forwardWindowsAuthToken="true"
        try:
            # Try to open the thread token (this is what HttpPlatformHandler sets)
            thread_token = win32security.OpenThreadToken(
                win32api.GetCurrentThread(),
                win32security.TOKEN_QUERY | win32security.TOKEN_IMPERSONATE,
                False  # OpenAsSelf=False means use the impersonation token
            )
            
            if thread_token:
                # Get user information from the token
                token_info = win32security.GetTokenInformation(
                    thread_token,
                    win32security.TokenUser
                )
                user_sid = token_info[0]
                
                # Convert SID to account name (domain and username)
                account_name, domain, account_type = win32security.LookupAccountSid(
                    None,
                    user_sid
                )
                
                # Format as DOMAIN\username
                if domain:
                    windows_user = f"{domain}\\{account_name}"
                else:
                    windows_user = account_name
                
                win32api.CloseHandle(thread_token)
                
                print(f"DEBUG: Successfully retrieved username from thread token: {windows_user}")
                if logger.isEnabledFor(logging.DEBUG):
                    logger.debug(f"Successfully retrieved username from thread token: {windows_user}")
                
                return windows_user
            else:
                print("DEBUG: OpenThreadToken returned None, trying with OpenAsSelf=True")
                
        except Exception as e:
            error_code = win32api.GetLastError()
            print(f"DEBUG: OpenThreadToken failed (error {error_code}): {e}")
            # Try with OpenAsSelf=True
            try:
                thread_token = win32security.OpenThreadToken(
                    win32api.GetCurrentThread(),
                    win32security.TOKEN_QUERY,
                    True  # OpenAsSelf=True
                )
                
                if thread_token:
                    token_info = win32security.GetTokenInformation(
                        thread_token,
                        win32security.TokenUser
                    )
                    user_sid = token_info[0]
                    
                    account_name, domain, account_type = win32security.LookupAccountSid(
                        None,
                        user_sid
                    )
                    
                    if domain:
                        windows_user = f"{domain}\\{account_name}"
                    else:
                        windows_user = account_name
                    
                    win32api.CloseHandle(thread_token)
                    
                    print(f"DEBUG: Successfully retrieved username from thread token (OpenAsSelf=True): {windows_user}")
                    if logger.isEnabledFor(logging.DEBUG):
                        logger.debug(f"Successfully retrieved username from thread token (OpenAsSelf=True): {windows_user}")
                    
                    return windows_user
            except Exception as e2:
                print(f"DEBUG: OpenThreadToken with OpenAsSelf=True also failed: {e2}")
        
        # Method 2: Try process token as fallback
        try:
            process_token = win32security.OpenProcessToken(
                win32api.GetCurrentProcess(),
                win32security.TOKEN_QUERY
            )
            
            if process_token:
                token_info = win32security.GetTokenInformation(
                    process_token,
                    win32security.TokenUser
                )
                user_sid = token_info[0]
                
                account_name, domain, account_type = win32security.LookupAccountSid(
                    None,
                    user_sid
                )
                
                if domain:
                    windows_user = f"{domain}\\{account_name}"
                else:
                    windows_user = account_name
                
                win32api.CloseHandle(process_token)
                
                print(f"DEBUG: Successfully retrieved username from process token: {windows_user}")
                if logger.isEnabledFor(logging.DEBUG):
                    logger.debug(f"Successfully retrieved username from process token: {windows_user}")
                
                return windows_user
        except Exception as e:
            print(f"DEBUG: Process token approach failed: {e}")
        
        # Method 3: Try using the hex handle from header (if thread/process tokens don't work)
        # This is less reliable but might work in some configurations
        try:
            token_handle = int(auth_token_hex, 16)
            print(f"DEBUG: Trying to use token handle from header: {token_handle}")
            
            # Try to duplicate the token
            duplicated_token = win32security.DuplicateTokenEx(
                token_handle,
                win32security.TOKEN_QUERY,
                None,
                win32security.SecurityImpersonation,
                win32security.TokenPrimary
            )
            
            token_info = win32security.GetTokenInformation(
                duplicated_token,
                win32security.TokenUser
            )
            user_sid = token_info[0]
            
            account_name, domain, account_type = win32security.LookupAccountSid(
                None,
                user_sid
            )
            
            if domain:
                windows_user = f"{domain}\\{account_name}"
            else:
                windows_user = account_name
            
            win32api.CloseHandle(duplicated_token)
            
            print(f"DEBUG: Successfully retrieved username from header token handle: {windows_user}")
            if logger.isEnabledFor(logging.DEBUG):
                logger.debug(f"Successfully retrieved username from header token handle: {windows_user}")
            
            return windows_user
            
        except Exception as e:
            error_msg = f"All token methods failed. Last error: {e}"
            print(f"ERROR: {error_msg}")
            logger.error(error_msg)
            if logger.isEnabledFor(logging.DEBUG):
                import traceback
                logger.debug(traceback.format_exc())
            return None
        
    except ImportError:
        error_msg = "pywin32 is not installed. Please install it with: pip install pywin32"
        print(f"ERROR: {error_msg}")
        logger.error(error_msg)
        return None
    except Exception as e:
        error_msg = f"Error processing Windows Auth Token: {e}"
        print(f"ERROR: {error_msg}")
        logger.error(error_msg)
        import traceback
        if logger.isEnabledFor(logging.DEBUG):
            logger.debug(traceback.format_exc())
        print(traceback.format_exc())
        return None

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
