from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class UserContext(BaseModel):
    user_id: UUID


class WorkoutImportPayload(BaseModel):
    user_id: UUID
    source: str = Field(min_length=1)
    source_workout_id: str = Field(min_length=1)
    started_at: datetime
    ended_at: datetime
    duration_sec: int = Field(gt=0)
    distance_m: float = Field(gt=0)
