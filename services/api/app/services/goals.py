from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.repos.goals import create_goal_history, enqueue_goal_refresh_job, ensure_user, get_current_goal, upsert_current_goal


class GoalUpdatePayload(BaseModel):
    primary_goal_type: str = Field(min_length=1)
    target_time_sec: int | None = Field(default=None, gt=0)
    target_date: date | None = None
    weekly_run_days: int | None = Field(default=None, ge=1, le=7)
    secondary_goal_types: list[str] | None = None


class GoalUpdateResult(BaseModel):
    primary_goal_type: str
    target_time_sec: int | None = None
    target_date: date | None = None
    weekly_run_days: int | None = None
    secondary_goal_types: list[str] | None = None
    history_recorded: bool
    refresh_job_id: str


def read_current_goal(session: Session, user_id: UUID) -> GoalUpdateResult | None:
    goal = get_current_goal(session, user_id)
    if goal is None:
        return None

    return GoalUpdateResult(
        primary_goal_type=goal.primary_goal_type,
        target_time_sec=goal.target_time_sec,
        target_date=goal.target_date,
        weekly_run_days=goal.weekly_run_days,
        secondary_goal_types=goal.secondary_goal_types,
        history_recorded=False,
        refresh_job_id="",
    )


def update_current_goal(session: Session, user_id: UUID, payload: GoalUpdatePayload) -> GoalUpdateResult:
    ensure_user(session, user_id)
    data = payload.model_dump()
    goal = upsert_current_goal(session, user_id, data)
    create_goal_history(session, user_id, data)
    job = enqueue_goal_refresh_job(session, user_id)
    session.commit()

    return GoalUpdateResult(
        primary_goal_type=goal.primary_goal_type,
        target_time_sec=goal.target_time_sec,
        target_date=goal.target_date,
        weekly_run_days=goal.weekly_run_days,
        secondary_goal_types=goal.secondary_goal_types,
        history_recorded=True,
        refresh_job_id=str(job.id),
    )
