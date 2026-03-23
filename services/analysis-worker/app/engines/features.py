from __future__ import annotations

from pydantic import BaseModel, Field


class WorkoutLap(BaseModel):
    lap_index: int
    duration_sec: int
    distance_m: float


class WorkoutSummary(BaseModel):
    distance_m: float
    duration_sec: int
    avg_heart_rate: float | None = None
    laps: list[WorkoutLap] = Field(default_factory=list)


class PostWorkoutFeedback(BaseModel):
    rpe: int | None = None
    fatigue: int | None = None
    soreness: int | None = None
    breathing_load: int | None = None
    confidence: int | None = None


class RecentLoadSummary(BaseModel):
    last_7d_distance_m: float = 0
    last_28d_distance_m: float = 0


class AnalysisContext(BaseModel):
    recent_load: RecentLoadSummary
    feedback: PostWorkoutFeedback
    workout: WorkoutSummary


class FeatureSummary(BaseModel):
    average_pace_sec_per_km: float
    positive_split_pct: float
    heart_rate_drift_pct: float


def compute_features(context: AnalysisContext) -> FeatureSummary:
    average_pace_sec_per_km = context.workout.duration_sec / (context.workout.distance_m / 1000)

    positive_split_pct = 0.0
    if len(context.workout.laps) >= 2:
        midpoint = len(context.workout.laps) // 2
        first_half = sum(lap.duration_sec for lap in context.workout.laps[:midpoint])
        second_half = sum(lap.duration_sec for lap in context.workout.laps[midpoint:])
        if first_half > 0:
            positive_split_pct = ((second_half - first_half) / first_half) * 100

    heart_rate_drift_pct = 0.0
    if context.workout.avg_heart_rate is not None:
        heart_rate_drift_pct = max(context.workout.avg_heart_rate - 150, 0) / 150 * 100

    return FeatureSummary(
        average_pace_sec_per_km=average_pace_sec_per_km,
        positive_split_pct=positive_split_pct,
        heart_rate_drift_pct=heart_rate_drift_pct,
    )
