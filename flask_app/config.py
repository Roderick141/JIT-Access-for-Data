"""
Configuration for JIT Access Framework Flask Application
"""
import os
from pathlib import Path
from dotenv import load_dotenv

# Try to load from settings.env first (if it exists), otherwise try .env
env_file = Path(__file__).parent / 'settings.env'
if env_file.exists():
    load_dotenv(dotenv_path=env_file)
else:
    # Fall back to .env if settings.env doesn't exist
    load_dotenv()

class Config:
    """Base configuration"""
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    
    # Database configuration - Uses SQL Server Authentication (service account)
    DB_SERVER = os.environ.get('DB_SERVER') or 'localhost'
    DB_NAME = os.environ.get('DB_NAME') or 'DMAP_JIT_Permissions'
    DB_DRIVER = os.environ.get('DB_DRIVER') or '{ODBC Driver 17 for SQL Server}'
    DB_USERNAME = os.environ.get('DB_USERNAME') or ''  # Service account username
    DB_PASSWORD = os.environ.get('DB_PASSWORD') or ''  # Service account password
    
    @property
    def SQLALCHEMY_DATABASE_URI(self):
        return (
            f"mssql+pyodbc://{self.DB_USERNAME}:{self.DB_PASSWORD}@{self.DB_SERVER}/{self.DB_NAME}"
            f"?driver={self.DB_DRIVER.replace(' ', '+')}"
        )
    
    @property
    def DB_CONNECTION_STRING(self):
        """Connection string for direct pyodbc connection using SQL Server Authentication"""
        return (
            f"DRIVER={self.DB_DRIVER};"
            f"SERVER={self.DB_SERVER};"
            f"DATABASE={self.DB_NAME};"
            f"UID={self.DB_USERNAME};"
            f"PWD={self.DB_PASSWORD};"
        )
    
    # Application settings
    FLASK_ENV = os.environ.get('FLASK_ENV') or 'development'
    DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'

