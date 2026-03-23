from uuid import UUID

from sqlalchemy.orm import Session

from app.repos.feedback import get_feedback_by_workout
from app.repos.plans import get_current_plan, list_plan_items
from app.repos.workouts import count_pending_analysis_jobs, get_latest_analysis_snapshot, get_latest_workout


def read_home(session: Session, user_id: UUID) -> dict:
    latest_workout = get_latest_workout(session, user_id)
    latest_feedback = get_feedback_by_workout(session, latest_workout.id) if latest_workout is not None else None
    latest_snapshot = get_latest_analysis_snapshot(session, latest_workout.id) if latest_workout is not None else None

    current_plan = get_current_plan(session, user_id)
    plan_items = list_plan_items(session, current_plan.id, days=7) if current_plan is not None else []
    changed_items = [item for item in plan_items if item.changed]

    next_workout = _serialize_plan_item(plan_items[0]) if plan_items else _serialize_snapshot_next_workout(latest_snapshot)

    latest_workout_summary = None
    if latest_workout is not None:
        latest_workout_summary = {
            "id": str(latest_workout.id),
            "started_at": latest_workout.started_at.isoformat(),
            "distance_m": latest_workout.distance_m,
            "duration_sec": latest_workout.duration_sec,
            "avg_pace_sec_per_km": latest_workout.avg_pace_sec_per_km,
            "avg_heart_rate": latest_workout.avg_heart_rate,
            "analysis_mode": latest_snapshot.mode if latest_snapshot is not None else None,
        }

    return {
        "next_workout": next_workout,
        "latest_workout_summary": latest_workout_summary,
        "plan_change_summary": {
            "has_changes": bool(changed_items),
            "changed_items": len(changed_items),
            "reasons": [item.change_reason for item in changed_items if item.change_reason],
        },
        "todos": {
            "needs_feedback": latest_workout is not None and latest_feedback is None,
            "sync_pending": count_pending_analysis_jobs(session, user_id) > 0,
        },
    }


def _serialize_plan_item(item) -> dict:
    return {
        "scheduled_date": item.scheduled_date.isoformat(),
        "workout_type": item.workout_type,
        "type": item.workout_type,
        "duration_min": item.duration_min,
        "distance_m": item.distance_m,
        "intensity": item.intensity,
        "changed": item.changed,
        "change_reason": item.change_reason,
    }


def _serialize_snapshot_next_workout(snapshot) -> dict | None:
    if snapshot is None or not snapshot.decision_json:
        return None
    next_workout = snapshot.decision_json.get("next_workout", {})
    if not next_workout:
        return None
    return {
        "type": next_workout.get("type"),
        "duration_min": next_workout.get("duration_min"),
        "distance_m": next_workout.get("distance_m"),
        "intensity": next_workout.get("intensity"),
    }
