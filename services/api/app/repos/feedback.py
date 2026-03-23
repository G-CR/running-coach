from uuid import UUID

from sqlalchemy.orm import Session

from app.db.models import FeedbackTagModel, PostWorkoutFeedbackModel, PostWorkoutFeedbackTagLinkModel


def get_feedback_by_workout(session: Session, workout_id: UUID) -> PostWorkoutFeedbackModel | None:
    return session.query(PostWorkoutFeedbackModel).filter_by(workout_session_id=workout_id).one_or_none()


def get_tags_by_display_names(session: Session, selected_tags: list[str]) -> list[FeedbackTagModel]:
    if not selected_tags:
        return []
    return session.query(FeedbackTagModel).filter(FeedbackTagModel.display_name.in_(selected_tags)).all()


def upsert_feedback(session: Session, user_id: UUID, workout_id: UUID, payload: dict) -> PostWorkoutFeedbackModel:
    feedback = get_feedback_by_workout(session, workout_id)
    if feedback is None:
        feedback = PostWorkoutFeedbackModel(user_id=user_id, workout_session_id=workout_id, **payload)
        session.add(feedback)
    else:
        for key, value in payload.items():
            setattr(feedback, key, value)
    session.flush()
    return feedback


def replace_feedback_tags(session: Session, feedback_id: UUID, tag_ids: list[UUID]) -> None:
    session.query(PostWorkoutFeedbackTagLinkModel).filter_by(feedback_id=feedback_id).delete()
    for tag_id in tag_ids:
        session.add(PostWorkoutFeedbackTagLinkModel(feedback_id=feedback_id, tag_id=tag_id))
    session.flush()
