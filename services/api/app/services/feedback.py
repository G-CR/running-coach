from uuid import UUID

from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.repos.feedback import get_tags_by_display_names, replace_feedback_tags, upsert_feedback
from app.repos.workouts import get_workout_by_id
from app.services.jobs import enqueue_analysis_job


class FeedbackPayload(BaseModel):
    rpe: int | None = Field(default=None, ge=1, le=10)
    fatigue: int | None = Field(default=None, ge=1, le=5)
    soreness: int | None = Field(default=None, ge=1, le=5)
    breathing_load: int | None = Field(default=None, ge=1, le=5)
    confidence: int | None = Field(default=None, ge=1, le=5)
    selected_tags: list[str] = Field(default_factory=list)
    free_text: str | None = None


class FeedbackSubmissionResult(BaseModel):
    analysis_requeued: bool
    analysis_job_id: str


def submit_feedback(session: Session, user_id: UUID, workout_id: UUID, payload: FeedbackPayload) -> FeedbackSubmissionResult:
    workout = get_workout_by_id(session, user_id, workout_id)
    if workout is None:
        raise ValueError("Workout not found")

    tags = get_tags_by_display_names(session, payload.selected_tags)
    if len(tags) != len(payload.selected_tags):
        raise ValueError("Unknown feedback tag")

    feedback = upsert_feedback(
        session,
        user_id=user_id,
        workout_id=workout_id,
        payload=payload.model_dump(exclude={"selected_tags"}),
    )
    replace_feedback_tags(session, feedback.id, [tag.id for tag in tags])
    analysis_job_id = enqueue_analysis_job(session, user_id, workout_id, "feedback")
    session.commit()
    return FeedbackSubmissionResult(analysis_requeued=True, analysis_job_id=analysis_job_id)
