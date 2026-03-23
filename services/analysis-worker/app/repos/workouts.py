from __future__ import annotations

from datetime import timedelta
from uuid import UUID

from sqlalchemy import func
from sqlalchemy.orm import Session

from domain.enums import AnalysisJobStatus

from app.core.db import get_api_models
from app.engines.features import AnalysisContext, PostWorkoutFeedback, RecentLoadSummary, WorkoutLap, WorkoutSummary


def update_job_status(session: Session, job_id: UUID, status: AnalysisJobStatus, error_message: str | None = None):
    models = get_api_models()
    job = session.get(models.AnalysisJobModel, job_id)
    if job is None:
        raise ValueError(f"Analysis job {job_id} not found")
    job.status = status.value
    job.error_message = error_message
    session.flush()
    return job


def load_analysis_context(session: Session, job_id: UUID) -> AnalysisContext:
    models = get_api_models()
    job = session.get(models.AnalysisJobModel, job_id)
    if job is None:
        raise ValueError(f"Analysis job {job_id} not found")
    if job.workout_session_id is None:
        raise ValueError(f"Analysis job {job_id} does not reference a workout")

    workout = session.get(models.WorkoutSessionModel, job.workout_session_id)
    if workout is None:
        raise ValueError(f"Workout {job.workout_session_id} not found")

    feedback = (
        session.query(models.PostWorkoutFeedbackModel)
        .filter_by(workout_session_id=workout.id)
        .one_or_none()
    )
    laps = (
        session.query(models.WorkoutLapModel)
        .filter_by(workout_session_id=workout.id)
        .order_by(models.WorkoutLapModel.lap_index.asc())
        .all()
    )

    last_7d_distance_m = _sum_recent_distance(session, job.user_id, workout.started_at, window_days=7)
    last_28d_distance_m = _sum_recent_distance(session, job.user_id, workout.started_at, window_days=28)

    return AnalysisContext(
        recent_load=RecentLoadSummary(
            last_7d_distance_m=last_7d_distance_m,
            last_28d_distance_m=last_28d_distance_m,
        ),
        feedback=PostWorkoutFeedback(
            rpe=feedback.rpe if feedback is not None else None,
            fatigue=feedback.fatigue if feedback is not None else None,
            soreness=feedback.soreness if feedback is not None else None,
            breathing_load=feedback.breathing_load if feedback is not None else None,
            confidence=feedback.confidence if feedback is not None else None,
        ),
        workout=WorkoutSummary(
            distance_m=workout.distance_m,
            duration_sec=workout.duration_sec,
            avg_heart_rate=workout.avg_heart_rate,
            laps=[
                WorkoutLap(
                    lap_index=lap.lap_index,
                    duration_sec=lap.duration_sec,
                    distance_m=lap.distance_m,
                )
                for lap in laps
            ],
        ),
    )


def _sum_recent_distance(session: Session, user_id: UUID, reference_started_at, window_days: int) -> float:
    models = get_api_models()
    cutoff = reference_started_at - timedelta(days=window_days)
    total = (
        session.query(func.coalesce(func.sum(models.WorkoutSessionModel.distance_m), 0.0))
        .filter(models.WorkoutSessionModel.user_id == user_id)
        .filter(models.WorkoutSessionModel.started_at >= cutoff)
        .filter(models.WorkoutSessionModel.started_at < reference_started_at)
        .scalar()
    )
    return float(total or 0.0)
