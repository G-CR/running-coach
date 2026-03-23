from uuid import UUID

from pydantic import BaseModel
from sqlalchemy.orm import Session

from domain.schemas import WorkoutImportPayload

from app.repos.workouts import (
    create_analysis_job,
    create_workout_distributions,
    create_workout_laps,
    create_workout_raw,
    create_workout_session,
    get_workout_by_source_key,
)


class WorkoutImportResult(BaseModel):
    workout_id: str
    deduplicated: bool
    import_job_id: str | None = None
    analysis_job_id: str | None = None


def import_workout(session: Session, user_id: UUID, payload: WorkoutImportPayload) -> WorkoutImportResult:
    existing = get_workout_by_source_key(session, user_id, payload.source, payload.source_workout_id)
    if existing is not None:
        return WorkoutImportResult(workout_id=str(existing.id), deduplicated=True)

    create_workout_raw(
        session=session,
        user_id=user_id,
        source=payload.source,
        source_workout_id=payload.source_workout_id,
        raw_payload=payload.raw_payload or payload.model_dump(mode="json"),
    )
    workout = create_workout_session(session, user_id, payload)
    create_workout_laps(session, workout.id, payload.laps)
    create_workout_distributions(session, workout.id, payload.distributions)
    import_job = create_analysis_job(session, user_id, workout.id, "import")
    analysis_job = create_analysis_job(session, user_id, workout.id, "analyze")
    session.commit()

    return WorkoutImportResult(
        workout_id=str(workout.id),
        deduplicated=False,
        import_job_id=str(import_job.id),
        analysis_job_id=str(analysis_job.id),
    )
