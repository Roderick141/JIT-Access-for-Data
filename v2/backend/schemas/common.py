from typing import Any, Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    ok: bool
    data: T | None = None
    message: str | None = None
    error: str | None = None


def success(data: Any = None, message: str | None = None) -> dict[str, Any]:
    return {"ok": True, "data": data, "message": message}


def failure(error: str, status_code: int = 400) -> tuple[dict[str, Any], int]:
    return ({"ok": False, "error": error}, status_code)

