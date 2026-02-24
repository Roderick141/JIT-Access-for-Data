from pydantic import BaseModel


class AuditLogModel(BaseModel):
    AuditLogId: int
    EventType: str
    EventUtc: str
    UserId: str | None = None
    Details: str | None = None

