"""
Configuration for JIT Access Framework Flask Application
"""
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    """Base configuration"""
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    
    # Database configuration
    DB_SERVER = os.environ.get('DB_SERVER') or 'localhost'
    DB_NAME = os.environ.get('DB_NAME') or 'DMAP_JIT_Permissions'
    DB_DRIVER = os.environ.get('DB_DRIVER') or '{ODBC Driver 17 for SQL Server}'
    DB_TRUSTED_CONNECTION = os.environ.get('DB_TRUSTED_CONNECTION', 'yes')
    
    @property
    def SQLALCHEMY_DATABASE_URI(self):
        return (
            f"mssql+pyodbc://{self.DB_SERVER}/{self.DB_NAME}"
            f"?driver={self.DB_DRIVER.replace(' ', '+')}"
            f"&Trusted_Connection={self.DB_TRUSTED_CONNECTION}"
        )
    
    @property
    def DB_CONNECTION_STRING(self):
        """Connection string for direct pyodbc connection"""
        return (
            f"DRIVER={self.DB_DRIVER};"
            f"SERVER={self.DB_SERVER};"
            f"DATABASE={self.DB_NAME};"
            f"Trusted_Connection={self.DB_TRUSTED_CONNECTION};"
        )
    
    # Application settings
    FLASK_ENV = os.environ.get('FLASK_ENV') or 'development'
    DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'

