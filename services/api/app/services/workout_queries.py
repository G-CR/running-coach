from uuid import UUID

from sqlalchemy.orm import Session

from app.repos.workouts import get_workout_by_id, get_workout_distributions, get_workout_laps, list_workouts


def read_workout_list(session: Session, user_id: UUID) -> list[dict]:
    return [
        {
            "id": str(item.id),
            "source": item.source,
            "source_workout_id": item.source_workout_id,
            "started_at": item.started_at.isoformat(),
            "duration_sec": item.duration_sec,
            "distance_m": item.distance_m,
            "avg_heart_rate": item.avg_heart_rate,
        }
        for item in list_workouts(session, user_id)
    ]


def read_workout_detail(session: Session, user_id: UUID, workout_id: UUID) -> dict | None:
    workout = get_workout_by_id(session, user_id, workout_id)
    if workout is None:
        return None

    laps = [
        {
            "lap_index": lap.lap_index,
            "distance_m": lap.distance_m,
            "duration_sec": lap.duration_sec,
            "avg_pace_sec_per_km": lap.avg_pace_sec_per_km,
            "avg_heart_rate": lap.avg_heart_rate,
            "avg_cadence": lap.avg_cadence,
        }
        for lap in get_workout_laps(session, workout.id)
    ]
    distributions = {
        key: [
            {
                "bucket_key": item.bucket_key,
                "duration_sec": item.duration_sec,
                "distance_m": item.distance_m,
                "percentage": item.percentage,
            }
            for item in values
        ]
        for key, values in get_workout_distributions(session, workout.id).items()
    }

    return {
        "id": str(workout.id),
        "source": workout.source,
        "source_workout_id": workout.source_workout_id,
        "started_at": workout.started_at.isoformat(),
        "ended_at": workout.ended_at.isoformat(),
        "duration_sec": workout.duration_sec,
        "distance_m": workout.distance_m,
        "avg_heart_rate": workout.avg_heart_rate,
        "max_heart_rate": workout.max_heart_rate,
        "avg_cadence": workout.avg_cadence,
        "laps": laps,
        "distributions": distributions,
    }
