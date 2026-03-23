from typing import Literal
from uuid import UUID, uuid4

from sqlalchemy.orm import Session

from app.db.models import AnalysisJobModel

TriggerType = Literal["import", "analyze", "feedback", "goal_change"]


def _build_dedupe_key(trigger: TriggerType, workout_id: UUID | None) -> str | None:
    if trigger in {"feedback", "goal_change"} and workout_id is not None:
        return f"{trigger}:{workout_id}"
    return None


def enqueue_analysis_job(session: Session, user_id: UUID, workout_id: UUID | None, trigger: TriggerType) -> str:
    dedupe_key = _build_dedupe_key(trigger, workout_id)
    if dedupe_key is not None:
        existing = session.query(AnalysisJobModel).filter_by(dedupe_key=dedupe_key).one_or_none()
        if existing is not None:
            return str(existing.id)

    job = AnalysisJobModel(
        id=uuid4(),
        user_id=user_id,
        workout_session_id=workout_id,
        trigger=trigger,
        status="queued",
        dedupe_key=dedupe_key,
    )
    session.add(job)
    session.flush()
    return str(job.id)
