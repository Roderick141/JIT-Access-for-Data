from pydantic import BaseModel


class RoleModel(BaseModel):
    RoleId: int
    RoleName: str
    Description: str | None = None
    SensitivityLevel: str | None = None

