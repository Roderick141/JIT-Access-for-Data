from functools import lru_cache
from typing import List

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", case_sensitive=False)

    app_name: str = "JIT Access API"
    app_env: str = "dev"
    app_host: str = "127.0.0.1"
    app_port: int = 8000
    app_debug: bool = True

    db_server: str
    db_name: str
    db_driver: str = "{ODBC Driver 18 for SQL Server}"
    db_username: str
    db_password: str
    db_encrypt: str = "yes"
    db_trust_server_certificate: str = "yes"

    cors_origins: List[str] = ["http://127.0.0.1:5173", "http://localhost:5173"]
    jit_fake_user: str | None = None

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: object) -> object:
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()

