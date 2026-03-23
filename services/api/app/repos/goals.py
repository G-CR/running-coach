from uuid import UUID, uuid4

from sqlalchemy.orm import Session

from app.db.models import AnalysisJobModel, GoalProfileCurrentModel, GoalProfileHistoryModel, UserModel


def ensure_user(session: Session, user_id: UUID) -> UserModel:
    user = session.get(UserModel, user_id)
    if user is not None:
        return user

    user = UserModel(id=user_id)
    session.add(user)
    session.flush()
    return user


def get_current_goal(session: Session, user_id: UUID) -> GoalProfileCurrentModel | None:
    return session.query(GoalProfileCurrentModel).filter_by(user_id=user_id).one_or_none()


def upsert_current_goal(session: Session, user_id: UUID, payload: dict) -> GoalProfileCurrentModel:
    goal = get_current_goal(session, user_id)
    if goal is None:
        goal = GoalProfileCurrentModel(user_id=user_id, **payload)
        session.add(goal)
    else:
        for key, value in payload.items():
            setattr(goal, key, value)
    session.flush()
    return goal


def create_goal_history(session: Session, user_id: UUID, payload: dict) -> GoalProfileHistoryModel:
    history = GoalProfileHistoryModel(user_id=user_id, **payload)
    session.add(history)
    session.flush()
    return history


def enqueue_goal_refresh_job(session: Session, user_id: UUID) -> AnalysisJobModel:
    job = AnalysisJobModel(
        id=uuid4(),
        user_id=user_id,
        trigger="goal_change",
        status="queued",
    )
    session.add(job)
    session.flush()
    return job
