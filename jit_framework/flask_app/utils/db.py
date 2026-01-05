"""
Database utility functions for JIT Access Framework
"""
import pyodbc
from flask import current_app, g
from functools import wraps

def get_db_connection():
    """Get database connection using SQL Server Authentication (service account)"""
    if 'db' not in g:
        g.db = pyodbc.connect(current_app.config['DB_CONNECTION_STRING'])
    return g.db

def close_db(e=None):
    """Close database connection"""
    db = g.pop('db', None)
    if db is not None:
        db.close()

def execute_procedure(procedure_name, params=None, fetch=True):
    """
    Execute a stored procedure and return results
    
    Args:
        procedure_name: Name of the stored procedure (e.g., 'jit.sp_User_ResolveCurrentUser')
        params: Dictionary of parameters {param_name: value}
        fetch: Whether to fetch results (for SELECT procedures)
    
    Returns:
        List of result rows (as dictionaries) if fetch=True, else None
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Build parameter list
        if params:
            param_placeholders = ', '.join([f'@{k}=?' for k in params.keys()])
            sql = f"EXEC {procedure_name} {param_placeholders}"
            values = list(params.values())
        else:
            sql = f"EXEC {procedure_name}"
            values = []
        
        cursor.execute(sql, values)
        
        if fetch:
            # Get column names
            columns = [column[0] for column in cursor.description] if cursor.description else []
            
            # Fetch all rows
            rows = cursor.fetchall()
            
            # Convert to list of dictionaries
            results = [dict(zip(columns, row)) for row in rows] if columns else []
            
            # Handle output parameters if any
            while cursor.nextset():
                if cursor.description:
                    columns = [column[0] for column in cursor.description]
                    rows = cursor.fetchall()
                    results.extend([dict(zip(columns, row)) for row in rows])
            
            conn.commit()
            return results
        else:
            conn.commit()
            return None
            
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cursor.close()

def execute_query(query, params=None):
    """
    Execute a SQL query and return results
    
    Args:
        query: SQL query string
        params: List of parameters for parameterized query
    
    Returns:
        List of result rows (as dictionaries)
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        
        columns = [column[0] for column in cursor.description] if cursor.description else []
        rows = cursor.fetchall()
        results = [dict(zip(columns, row)) for row in rows] if columns else []
        
        conn.commit()
        return results
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cursor.close()

