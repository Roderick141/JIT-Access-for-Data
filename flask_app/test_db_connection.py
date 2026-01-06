"""
Database Connection Test Script
Tests the Flask application database connection configuration
"""
import sys
import os
from pathlib import Path

# Add the flask_app directory to the path so we can import config
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Explicitly load .env file before importing config
from dotenv import load_dotenv
env_file = Path(__file__).parent / 'settings.env'
if env_file.exists():
    load_dotenv(dotenv_path=env_file)
    print(f"Loaded environment from: settings.env")
else:
    env_file = Path(__file__).parent / '.env'
    if env_file.exists():
        load_dotenv(dotenv_path=env_file)
        print(f"Loaded environment from: .env")
    else:
        load_dotenv()
        print("Attempted to load .env (file may not exist, using environment variables)")

try:
    import pyodbc
    from config import Config
except ImportError as e:
    print(f"ERROR: Failed to import required modules: {e}")
    print("\nPlease ensure you have installed the required packages:")
    print("  pip install pyodbc python-dotenv")
    sys.exit(1)

def test_database_connection():
    """
    Test database connection using Flask configuration
    """
    print("=" * 60)
    print("Database Connection Test")
    print("=" * 60)
    print()
    
    # Check which env file exists
    env_file_path = Path(__file__).parent
    settings_env = env_file_path / 'settings.env'
    dot_env = env_file_path / '.env'
    
    if settings_env.exists():
        print(f"Found: settings.env")
    elif dot_env.exists():
        print(f"Found: .env")
    else:
        print("⚠️  No .env or settings.env file found!")
        print("   Using environment variables only")
    print()
    
    # Load configuration
    config = Config()
    
    # Display configuration (mask password)
    print("Configuration:")
    print(f"  Server: {config.DB_SERVER}")
    print(f"  Database: {config.DB_NAME}")
    print(f"  Driver: {config.DB_DRIVER}")
    print(f"  Username: {config.DB_USERNAME}")
    print(f"  Password: {'*' * len(config.DB_PASSWORD) if config.DB_PASSWORD else '(not set)'}")
    print()
    
    # Validate configuration
    print("Validating configuration...")
    issues = []
    
    if not config.DB_SERVER:
        issues.append("  ❌ DB_SERVER is not set")
    else:
        print(f"  ✅ DB_SERVER: {config.DB_SERVER}")
    
    if not config.DB_NAME:
        issues.append("  ❌ DB_NAME is not set")
    else:
        print(f"  ✅ DB_NAME: {config.DB_NAME}")
    
    if not config.DB_DRIVER:
        issues.append("  ❌ DB_DRIVER is not set")
    else:
        print(f"  ✅ DB_DRIVER: {config.DB_DRIVER}")
    
    if not config.DB_USERNAME:
        issues.append("  ❌ DB_USERNAME is not set")
    else:
        print(f"  ✅ DB_USERNAME: {config.DB_USERNAME}")
    
    if not config.DB_PASSWORD:
        issues.append("  ❌ DB_PASSWORD is not set")
    else:
        print(f"  ✅ DB_PASSWORD: {'*' * min(len(config.DB_PASSWORD), 20)}")
    
    print()
    
    if issues:
        print("Configuration Issues Found:")
        for issue in issues:
            print(issue)
        print()
        print("Please check your .env file or environment variables.")
        return False
    
    # Test connection
    print("Testing database connection...")
    print()
    
    try:
        connection_string = config.DB_CONNECTION_STRING
        print(f"Connection string: {connection_string.replace(config.DB_PASSWORD, '*' * min(len(config.DB_PASSWORD), 20))}")
        print()
        
        conn = pyodbc.connect(connection_string, timeout=10)
        print("  ✅ Successfully connected to database!")
        print()
        
        # Test query - get database version
        print("Testing query execution...")
        cursor = conn.cursor()
        cursor.execute("SELECT @@VERSION AS Version")
        version = cursor.fetchone()[0]
        print(f"  ✅ Query executed successfully")
        print(f"  SQL Server Version: {version.split(chr(10))[0]}")
        print()
        
        # Test query - check if jit schema exists
        print("Checking for jit schema...")
        cursor.execute("""
            SELECT COUNT(*) 
            FROM sys.schemas 
            WHERE name = 'jit'
        """)
        schema_exists = cursor.fetchone()[0] > 0
        
        if schema_exists:
            print("  ✅ jit schema exists")
            print()
            
            # Check if Users table exists
            print("Checking for jit.Users table...")
            cursor.execute("""
                SELECT COUNT(*) 
                FROM sys.tables 
                WHERE schema_id = SCHEMA_ID('jit') 
                AND name = 'Users'
            """)
            users_table_exists = cursor.fetchone()[0] > 0
            
            if users_table_exists:
                print("  ✅ jit.Users table exists")
                print()
                
                # Count users
                cursor.execute("SELECT COUNT(*) FROM jit.Users")
                user_count = cursor.fetchone()[0]
                print(f"  User count: {user_count}")
                print()
                
                # Check permissions
                print("Checking database permissions...")
                try:
                    cursor.execute("SELECT TOP 1 UserId, LoginName FROM jit.Users")
                    test_row = cursor.fetchone()
                    if test_row:
                        print("  ✅ SELECT permission on jit.Users: OK")
                    else:
                        print("  ⚠️  SELECT permission: OK (table is empty)")
                    
                    # Test if we can execute a procedure (if it exists)
                    cursor.execute("""
                        SELECT COUNT(*) 
                        FROM sys.procedures 
                        WHERE schema_id = SCHEMA_ID('jit') 
                        AND name = 'sp_User_ResolveCurrentUser'
                    """)
                    proc_exists = cursor.fetchone()[0] > 0
                    
                    if proc_exists:
                        print("  ✅ Stored procedures found")
                    else:
                        print("  ⚠️  Stored procedures not found (may need to create them)")
                    
                except Exception as perm_error:
                    print(f"  ❌ Permission error: {perm_error}")
                    print("  Please check that the service account has appropriate permissions")
                
            else:
                print("  ⚠️  jit.Users table does not exist")
                print("  You may need to run the schema creation scripts")
        else:
            print("  ⚠️  jit schema does not exist")
            print("  You may need to run the schema creation scripts")
        
        cursor.close()
        conn.close()
        print()
        print("=" * 60)
        print("✅ Database connection test PASSED")
        print("=" * 60)
        return True
        
    except pyodbc.Error as e:
        error_code = e.args[0] if e.args else "Unknown"
        error_msg = str(e)
        print(f"  ❌ Connection failed!")
        print(f"  Error Code: {error_code}")
        print(f"  Error Message: {error_msg}")
        print()
        print("Common issues:")
        if "Login failed" in error_msg:
            print("  - Check DB_USERNAME and DB_PASSWORD in .env file")
            print("  - Verify the service account exists in SQL Server")
            print("  - Check if the password is correct")
        elif "Cannot open database" in error_msg:
            print("  - Check DB_NAME in .env file")
            print("  - Verify the database exists")
            print("  - Check if the service account has access to the database")
        elif "driver" in error_msg.lower() or "driver not found" in error_msg.lower():
            print("  - Check DB_DRIVER in .env file")
            print("  - Verify the ODBC driver is installed")
            print("  - Common drivers: {ODBC Driver 17 for SQL Server}")
        elif "server" in error_msg.lower() or "network" in error_msg.lower():
            print("  - Check DB_SERVER in .env file")
            print("  - Verify the server name is correct")
            print("  - Check network connectivity")
        print()
        print("=" * 60)
        print("❌ Database connection test FAILED")
        print("=" * 60)
        return False
        
    except Exception as e:
        print(f"  ❌ Unexpected error: {e}")
        print(f"  Error type: {type(e).__name__}")
        print()
        print("=" * 60)
        print("❌ Database connection test FAILED")
        print("=" * 60)
        return False

if __name__ == "__main__":
    success = test_database_connection()
    sys.exit(0 if success else 1)

