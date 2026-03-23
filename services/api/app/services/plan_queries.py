from uuid import UUID

from sqlalchemy.orm import Session

from app.repos.plans import get_current_plan, list_plan_items


def read_current_plan(session: Session, user_id: UUID, days: int = 7) -> dict:
    plan = get_current_plan(session, user_id)
    if plan is None:
        return {
            "plan_id": None,
            "version": 0,
            "window_start": None,
            "window_days": days,
            "items": [],
        }

    items = [
        {
            "day_index": item.day_index,
            "scheduled_date": item.scheduled_date.isoformat(),
            "workout_type": item.workout_type,
            "duration_min": item.duration_min,
            "distance_m": item.distance_m,
            "intensity": item.intensity,
            "changed": item.changed,
            "change_reason": item.change_reason,
        }
        for item in list_plan_items(session, plan.id, days=days)
    ]

    return {
        "plan_id": str(plan.id),
        "version": plan.version,
        "window_start": plan.window_start.isoformat(),
        "window_days": plan.window_days,
        "items": items,
    }
