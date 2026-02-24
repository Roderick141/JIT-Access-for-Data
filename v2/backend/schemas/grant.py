from pydantic import BaseModel


class GrantModel(BaseModel):
    GrantId: int
    UserId: str
    RoleId: int
    Status: str

