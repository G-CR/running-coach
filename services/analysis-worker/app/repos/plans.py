from __future__ import annotations

from datetime import timedelta
from uuid import UUID

from sqlalchemy import func
from sqlalchemy.orm import Session

from domain.enums import AnalysisMode

from app.core.db import get_api_models
from app.engines.features import AnalysisContext, FeatureSummary
from app.engines.planner import PlanDecision
from app.engines.rules import RuleResult


def write_analysis_snapshot(
    session: Session,
    job_id: UUID,
    context: AnalysisContext,
    features: FeatureSummary,
    rule_result: RuleResult,
    decision: PlanDecision,
    narrative: dict,
) -> bool:
    models = get_api_models()
    job = session.get(models.AnalysisJobModel, job_id)
    if job is None or job.workout_session_id is None:
        raise ValueError(f"Analysis job {job_id} is missing context")

    workout = session.get(models.WorkoutSessionModel, job.workout_session_id)
    if workout is None:
        raise ValueError(f"Workout {job.workout_session_id} not found")

    _upsert_feature(session, workout.id, "average_pace_sec_per_km", features.average_pace_sec_per_km)
    _upsert_feature(session, workout.id, "positive_split_pct", features.positive_split_pct)
    _upsert_feature(session, workout.id, "heart_rate_drift_pct", features.heart_rate_drift_pct)

    current_snapshot_version = (
        session.query(func.coalesce(func.max(models.AnalysisSnapshotModel.version), 0))
        .filter_by(workout_session_id=workout.id)
        .scalar()
    )
    snapshot = models.AnalysisSnapshotModel(
        user_id=job.user_id,
        workout_session_id=workout.id,
        analysis_job_id=job.id,
        version=int(current_snapshot_version or 0) + 1,
        mode=rule_result.mode.value,
        decision_confidence=_decision_confidence(rule_result.mode),
        input_summary={
            **context.model_dump(mode="json"),
            "features": features.model_dump(mode="json"),
        },
        decision_json=decision.model_dump(mode="json"),
        narrative_json=narrative,
    )
    session.add(snapshot)
    session.flush()

    session.query(models.TrainingPlanModel).filter_by(user_id=job.user_id, is_current=True).update({"is_current": False})

    window_start = workout.started_at.date() + timedelta(days=1)
    current_plan_version = (
        session.query(func.coalesce(func.max(models.TrainingPlanModel.version), 0))
        .filter_by(user_id=job.user_id, window_start=window_start)
        .scalar()
    )
    plan = models.TrainingPlanModel(
        user_id=job.user_id,
        training_block_id=None,
        source_analysis_snapshot_id=snapshot.id,
        window_start=window_start,
        window_days=7,
        version=int(current_plan_version or 0) + 1,
        is_current=True,
    )
    session.add(plan)
    session.flush()

    for item in _build_plan_items(decision, window_start):
        session.add(
            models.TrainingPlanItemModel(
                training_plan_id=plan.id,
                day_index=item["day_index"],
                scheduled_date=item["scheduled_date"],
                workout_type=item["workout_type"],
                duration_min=item["duration_min"],
                distance_m=item["distance_m"],
                intensity=item["intensity"],
                changed=item["changed"],
                change_reason=item["change_reason"],
            )
        )
    session.flush()
    return True


def _upsert_feature(session: Session, workout_id: UUID, feature_key: str, value_float: float) -> None:
    models = get_api_models()
    feature = (
        session.query(models.WorkoutDerivedFeatureModel)
        .filter_by(workout_session_id=workout_id, feature_key=feature_key)
        .one_or_none()
    )
    if feature is None:
        feature = models.WorkoutDerivedFeatureModel(
            workout_session_id=workout_id,
            feature_key=feature_key,
        )
        session.add(feature)
    feature.value_float = value_float
    feature.value_text = None
    feature.value_json = None
    feature.value_source = "derived"
    feature.availability_status = "available"
    feature.confidence_score = 0.8
    session.flush()


def _decision_confidence(mode: AnalysisMode) -> str:
    if mode == AnalysisMode.DEGRADED:
        return "low"
    if mode == AnalysisMode.CONSERVATIVE:
        return "medium"
    return "high"


def _build_plan_items(decision: PlanDecision, window_start):
    reason = "; ".join(decision.seven_day_adjustment.notes) if decision.seven_day_adjustment.notes else None
    if decision.next_workout.type == "recovery_run":
        template = [
            ("recovery_run", decision.next_workout.duration_min, decision.next_workout.intensity, True),
            ("rest", None, "rest", True),
            ("easy_run", 40, "z2", True),
            ("rest", None, "rest", False),
            ("easy_run", 45, "z2", False),
            ("rest", None, "rest", False),
            ("long_run", 75, "z2", False),
        ]
    elif decision.seven_day_adjustment.changed:
        template = [
            (decision.next_workout.type, decision.next_workout.duration_min, decision.next_workout.intensity, True),
            ("rest", None, "rest", True),
            ("easy_run", 45, "z2", True),
            ("rest", None, "rest", False),
            ("tempo_run", 30, "z3", False),
            ("rest", None, "rest", False),
            ("long_run", 80, "z2", False),
        ]
    else:
        template = [
            (decision.next_workout.type, decision.next_workout.duration_min, decision.next_workout.intensity, False),
            ("rest", None, "rest", False),
            ("tempo_run", 35, "z3", False),
            ("rest", None, "rest", False),
            ("easy_run", 45, "z2", False),
            ("rest", None, "rest", False),
            ("long_run", 90, "z2", False),
        ]

    items = []
    for day_index, (workout_type, duration_min, intensity, changed) in enumerate(template):
        items.append(
            {
                "day_index": day_index,
                "scheduled_date": window_start + timedelta(days=day_index),
                "workout_type": workout_type,
                "duration_min": duration_min,
                "distance_m": None,
                "intensity": intensity,
                "changed": changed,
                "change_reason": reason if changed else None,
            }
        )
    return items
