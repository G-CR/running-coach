from collections import defaultdict
from uuid import UUID, uuid4

from sqlalchemy.orm import Session

from app.db.models import (
    AnalysisJobModel,
    AnalysisSnapshotModel,
    WorkoutDerivedFeatureModel,
    WorkoutDistributionModel,
    WorkoutLapModel,
    WorkoutRawModel,
    WorkoutSessionModel,
)
from app.repos.goals import ensure_user


def get_workout_by_source_key(session: Session, user_id: UUID, source: str, source_workout_id: str) -> WorkoutSessionModel | None:
    return (
        session.query(WorkoutSessionModel)
        .filter_by(user_id=user_id, source=source, source_workout_id=source_workout_id)
        .one_or_none()
    )


def get_workout_by_id(session: Session, user_id: UUID, workout_id: UUID) -> WorkoutSessionModel | None:
    return session.query(WorkoutSessionModel).filter_by(user_id=user_id, id=workout_id).one_or_none()


def list_workouts(session: Session, user_id: UUID) -> list[WorkoutSessionModel]:
    return session.query(WorkoutSessionModel).filter_by(user_id=user_id).order_by(WorkoutSessionModel.started_at.desc()).all()


def get_latest_workout(session: Session, user_id: UUID) -> WorkoutSessionModel | None:
    return (
        session.query(WorkoutSessionModel)
        .filter_by(user_id=user_id)
        .order_by(WorkoutSessionModel.started_at.desc())
        .first()
    )


def create_workout_raw(
    session: Session,
    user_id: UUID,
    source: str,
    source_workout_id: str,
    raw_payload: dict | None,
) -> WorkoutRawModel:
    record = WorkoutRawModel(
        id=uuid4(),
        user_id=user_id,
        source=source,
        source_workout_id=source_workout_id,
        raw_payload=raw_payload,
    )
    session.add(record)
    session.flush()
    return record


def create_workout_session(session: Session, user_id: UUID, payload) -> WorkoutSessionModel:
    ensure_user(session, user_id)
    workout = WorkoutSessionModel(
        id=uuid4(),
        user_id=user_id,
        source=payload.source,
        source_workout_id=payload.source_workout_id,
        started_at=payload.started_at,
        ended_at=payload.ended_at,
        duration_sec=payload.duration_sec,
        distance_m=payload.distance_m,
        avg_heart_rate=payload.avg_heart_rate,
        max_heart_rate=payload.max_heart_rate,
        avg_cadence=payload.avg_cadence,
        is_outdoor=payload.is_outdoor,
        has_route=payload.has_route,
    )
    session.add(workout)
    session.flush()
    return workout


def create_workout_laps(session: Session, workout_id: UUID, laps) -> None:
    for lap in laps:
        session.add(
            WorkoutLapModel(
                workout_session_id=workout_id,
                lap_index=lap.lap_index,
                distance_m=lap.distance_m,
                duration_sec=lap.duration_sec,
                avg_pace_sec_per_km=lap.avg_pace_sec_per_km,
                avg_heart_rate=lap.avg_heart_rate,
                avg_cadence=lap.avg_cadence,
            )
        )
    session.flush()


def create_workout_distributions(session: Session, workout_id: UUID, distributions) -> None:
    for distribution in distributions:
        session.add(
            WorkoutDistributionModel(
                workout_session_id=workout_id,
                distribution_type=distribution.distribution_type,
                bucket_key=distribution.bucket_key,
                duration_sec=distribution.duration_sec,
                distance_m=distribution.distance_m,
                percentage=distribution.percentage,
            )
        )
    session.flush()


def create_analysis_job(session: Session, user_id: UUID, workout_id: UUID, trigger: str) -> AnalysisJobModel:
    job = AnalysisJobModel(
        id=uuid4(),
        user_id=user_id,
        workout_session_id=workout_id,
        trigger=trigger,
        status="queued",
    )
    session.add(job)
    session.flush()
    return job


def get_workout_laps(session: Session, workout_id: UUID) -> list[WorkoutLapModel]:
    return session.query(WorkoutLapModel).filter_by(workout_session_id=workout_id).order_by(WorkoutLapModel.lap_index.asc()).all()


def get_workout_distributions(session: Session, workout_id: UUID) -> dict[str, list[WorkoutDistributionModel]]:
    grouped: dict[str, list[WorkoutDistributionModel]] = defaultdict(list)
    for item in session.query(WorkoutDistributionModel).filter_by(workout_session_id=workout_id).all():
        grouped[item.distribution_type].append(item)
    return dict(grouped)


def get_latest_analysis_snapshot(session: Session, workout_id: UUID) -> AnalysisSnapshotModel | None:
    return (
        session.query(AnalysisSnapshotModel)
        .filter_by(workout_session_id=workout_id)
        .order_by(AnalysisSnapshotModel.version.desc(), AnalysisSnapshotModel.created_at.desc())
        .first()
    )


def get_derived_features(session: Session, workout_id: UUID) -> list[WorkoutDerivedFeatureModel]:
    return session.query(WorkoutDerivedFeatureModel).filter_by(workout_session_id=workout_id).all()


def count_pending_analysis_jobs(session: Session, user_id: UUID) -> int:
    return (
        session.query(AnalysisJobModel)
        .filter(AnalysisJobModel.user_id == user_id)
        .filter(AnalysisJobModel.status.in_(["queued", "running", "needs_retry"]))
        .count()
    )
