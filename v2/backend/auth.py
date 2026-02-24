from __future__ import annotations

import os

from fastapi import Header, HTTPException

from db import execute_query


def _pick_login(x_remote_user: str | None) -> str | None:
    from config import get_settings

    settings = get_settings()
    env = settings.app_env.lower()
    is_dev = env in {"dev", "development", "local"}

    if x_remote_user and x_remote_user.strip():
        return x_remote_user.strip()

    if is_dev:
        fake_user = (settings.jit_fake_user or "").strip()
        if fake_user:
            return fake_user

        env_user = (os.getenv("USERNAME") or os.getenv("USER") or "").strip()
        if env_user:
            return env_user

    return None


def get_current_user(x_remote_user: str | None = Header(default=None, alias="X-Remote-User")) -> dict:
    windows_username = _pick_login(x_remote_user)

    if not windows_username:
        raise HTTPException(status_code=401, detail="Missing X-Remote-User header.")

    search_pattern = f"%\\{windows_username}"
    rows = execute_query(
        """
        SELECT UserId, LoginName, GivenName, Surname, DisplayName,
               Email, Division, Department, JobTitle, SeniorityLevel,
               IsAdmin, IsApprover, IsDataSteward, IsActive
        FROM jit.Users
        WHERE (LoginName = ? OR LoginName LIKE ? OR LoginName = ?)
          AND IsActive = 1
        """,
        [windows_username, search_pattern, windows_username],
    )

    if not rows:
        raise HTTPException(
            status_code=401,
            detail="User not found. Please contact your administrator to create your account.",
        )

    return rows[0]


def require_approver(user: dict) -> None:
    if not (user.get("IsAdmin") or user.get("IsApprover") or user.get("IsDataSteward")):
        raise HTTPException(status_code=403, detail="Approver access required.")


def require_manager(user: dict) -> None:
    if not (user.get("IsAdmin") or user.get("IsDataSteward")):
        raise HTTPException(status_code=403, detail="Manager access required.")