from pydantic import BaseModel


class CurrentUser(BaseModel):
    UserId: str
    DisplayName: str | None = None
    Email: str | None = None
    IsAdmin: bool = False
    IsApprover: bool = False
    IsDataSteward: bool = False

