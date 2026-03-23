from uuid import UUID

from sqlalchemy.orm import Session

from app.db.models import TrainingPlanItemModel, TrainingPlanModel


def get_current_plan(session: Session, user_id: UUID) -> TrainingPlanModel | None:
    return (
        session.query(TrainingPlanModel)
        .filter_by(user_id=user_id, is_current=True)
        .order_by(TrainingPlanModel.created_at.desc())
        .first()
    )


def list_plan_items(session: Session, training_plan_id: UUID, days: int | None = None) -> list[TrainingPlanItemModel]:
    query = (
        session.query(TrainingPlanItemModel)
        .filter_by(training_plan_id=training_plan_id)
        .order_by(TrainingPlanItemModel.day_index.asc())
    )
    if days is not None:
        query = query.filter(TrainingPlanItemModel.day_index < days)
    return query.all()
