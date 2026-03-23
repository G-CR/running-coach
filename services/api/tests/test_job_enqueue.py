from uuid import UUID

from app.core.db import get_session_factory
from app.services.jobs import enqueue_analysis_job


def test_enqueue_analysis_job_deduplicates_feedback_trigger(imported_workout):
    session = get_session_factory()()
    try:
        first = enqueue_analysis_job(
            session=session,
            user_id=UUID(imported_workout.user_id),
            workout_id=UUID(imported_workout.id),
            trigger="feedback",
        )
        second = enqueue_analysis_job(
            session=session,
            user_id=UUID(imported_workout.user_id),
            workout_id=UUID(imported_workout.id),
            trigger="feedback",
        )
        assert first == second
    finally:
        session.close()
