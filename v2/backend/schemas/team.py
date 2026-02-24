from pydantic import BaseModel


class TeamModel(BaseModel):
    TeamId: int
    TeamName: str
    TeamDescription: str | None = None
    Department: str | None = None

