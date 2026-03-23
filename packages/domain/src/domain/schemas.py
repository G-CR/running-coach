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
    avg_heart_rate: float | None = None
    max_heart_rate: float | None = None
    avg_cadence: float | None = None
    is_outdoor: bool = True
    has_route: bool = False
    laps: list["WorkoutLapPayload"] = Field(default_factory=list)
    distributions: list["WorkoutDistributionPayload"] = Field(default_factory=list)
    raw_payload: dict | None = None


class WorkoutLapPayload(BaseModel):
    lap_index: int = Field(ge=1)
    distance_m: float = Field(gt=0)
    duration_sec: int = Field(gt=0)
    avg_pace_sec_per_km: float | None = None
    avg_heart_rate: float | None = None
    avg_cadence: float | None = None


class WorkoutDistributionPayload(BaseModel):
    distribution_type: str = Field(min_length=1)
    bucket_key: str = Field(min_length=1)
    duration_sec: int | None = None
    distance_m: float | None = None
    percentage: float | None = None
