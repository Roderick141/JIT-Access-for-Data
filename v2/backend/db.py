from __future__ import annotations

from contextlib import contextmanager
import re
from typing import Any

import pyodbc

from config import get_settings

_SP_NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*){1,2}$")
_PARAM_NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _connection_string() -> str:
    s = get_settings()
    return (
        f"DRIVER={s.db_driver};"
        f"SERVER={s.db_server};"
        f"DATABASE={s.db_name};"
        f"UID={s.db_username};"
        f"PWD={s.db_password};"
        f"Encrypt={s.db_encrypt};"
        f"TrustServerCertificate={s.db_trust_server_certificate};"
    )


@contextmanager
def get_connection() -> pyodbc.Connection:
    conn = pyodbc.connect(_connection_string())
    try:
        yield conn
    finally:
        conn.close()


def _rows_to_dicts(cursor: pyodbc.Cursor, rows: list[Any]) -> list[dict[str, Any]]:
    if not cursor.description:
        return []
    cols = [c[0] for c in cursor.description]
    return [dict(zip(cols, row)) for row in rows]


def execute_query(sql: str, params: list[Any] | tuple[Any, ...] | None = None) -> list[dict[str, Any]]:
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute(sql, params or [])
        rows = cur.fetchall() if cur.description else []
        result = _rows_to_dicts(cur, rows)
        conn.commit()
        return result


def execute_sp(name: str, params: dict[str, Any] | None = None, fetch: bool = True) -> list[dict[str, Any]]:
    if not _SP_NAME_RE.fullmatch(name):
        raise ValueError(f"Unsafe stored procedure name: {name!r}")

    with get_connection() as conn:
        cur = conn.cursor()
        if params:
            bad_keys = [k for k in params.keys() if not _PARAM_NAME_RE.fullmatch(k)]
            if bad_keys:
                raise ValueError(f"Unsafe stored procedure parameter name(s): {bad_keys!r}")
            placeholders = ", ".join([f"@{k}=?" for k in params.keys()])
            sql = f"EXEC {name} {placeholders}"
            values = list(params.values())
        else:
            sql = f"EXEC {name}"
            values = []

        cur.execute(sql, values)
        if not fetch:
            conn.commit()
            return []

        all_rows: list[dict[str, Any]] = []
        if cur.description:
            all_rows.extend(_rows_to_dicts(cur, cur.fetchall()))
        while cur.nextset():
            if cur.description:
                all_rows.extend(_rows_to_dicts(cur, cur.fetchall()))
        conn.commit()
        return all_rows

