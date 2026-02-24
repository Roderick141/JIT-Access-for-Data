from pydantic import BaseModel


class RequestModel(BaseModel):
    RequestId: int
    UserId: str
    Status: str
    RequestedDurationMinutes: int

