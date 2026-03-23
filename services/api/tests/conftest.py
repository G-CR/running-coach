import base64
import json
import sys
from datetime import timedelta
from pathlib import Path
from types import SimpleNamespace
from uuid import UUID, uuid4

import pytest
from fastapi.testclient import TestClient

API_ROOT = Path(__file__).resolve().parents[1]
DOMAIN_ROOT = Path(__file__).resolve().parents[3] / "packages" / "domain" / "src"
REPO_ROOT = Path(__file__).resolve().parents[3]
FIXTURE_ROOT = REPO_ROOT / "docs" / "fixtures" / "workouts"

sys.path.insert(0, str(API_ROOT))
sys.path.insert(0, str(DOMAIN_ROOT))

from app.core.db import get_session_factory
from app.db.models import (
    AnalysisSnapshotModel,
    FeedbackTagModel,
    PostWorkoutFeedbackModel,
    PostWorkoutFeedbackTagLinkModel,
    TrainingPlanItemModel,
    TrainingPlanModel,
    WorkoutDerivedFeatureModel,
    WorkoutSessionModel,
)
from app.main import app


def _b64url(value: dict) -> str:
    raw = json.dumps(value, separators=(",", ":")).encode()
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


@pytest.fixture()
def user_id() -> str:
    return str(uuid4())


@pytest.fixture()
def signed_token(user_id: str) -> str:
    header = {"alg": "none", "typ": "JWT"}
    payload = {"sub": user_id}
    return f"{_b64url(header)}.{_b64url(payload)}."


@pytest.fixture()
def auth_headers(signed_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {signed_token}"}


@pytest.fixture()
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture()
def db_session():
    session = get_session_factory()()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def healthkit_payload(user_id: str) -> dict:
    payload = json.loads((FIXTURE_ROOT / "healthkit-5k-easy.json").read_text())
    payload["user_id"] = user_id
    return payload


@pytest.fixture()
def imported_workout(client: TestClient, auth_headers: dict[str, str], healthkit_payload: dict) -> SimpleNamespace:
    response = client.post("/v1/workouts/import", json=healthkit_payload, headers=auth_headers)
    body = response.json()
    return SimpleNamespace(id=body["workout_id"], user_id=healthkit_payload["user_id"])


def _seed_analysis_bundle(db_session, workout_id: str, user_id: str, include_feedback: bool) -> SimpleNamespace:
    workout = db_session.get(WorkoutSessionModel, UUID(workout_id))
    assert workout is not None
    user_uuid = UUID(user_id)

    snapshot = AnalysisSnapshotModel(
        user_id=user_uuid,
        workout_session_id=workout.id,
        version=1,
        mode="protective",
        decision_confidence="high",
        input_summary={
            "recent_load": {"last_7d_distance_m": 12000, "last_28d_distance_m": 24000},
            "feedback": {"rpe": 9, "fatigue": 5, "soreness": 4},
            "workout": {"distance_m": workout.distance_m, "duration_sec": workout.duration_sec},
            "features": {
                "average_pace_sec_per_km": 360.0,
                "positive_split_pct": 2.2,
                "heart_rate_drift_pct": 1.3,
            },
        },
        decision_json={
            "next_workout": {"type": "recovery_run", "duration_min": 35, "intensity": "z1-z2"},
            "seven_day_adjustment": {
                "changed": True,
                "notes": ["Reduce volume and delay quality session"],
            },
            "reason_codes": ["high_fatigue"],
        },
        narrative_json={
            "session_summary": "Recent run suggests recovery first.",
            "next_workout_reason": "High fatigue after the latest run.",
            "week_adjustment_reason": "Reduce volume and delay quality session",
        },
    )
    db_session.add(snapshot)
    db_session.flush()

    plan = TrainingPlanModel(
        user_id=user_uuid,
        source_analysis_snapshot_id=snapshot.id,
        window_start=workout.started_at.date() + timedelta(days=1),
        window_days=7,
        version=1,
        is_current=True,
    )
    db_session.add(plan)
    db_session.flush()

    plan_items = [
        ("recovery_run", 35, "z1-z2", True),
        ("rest", None, "rest", True),
        ("easy_run", 40, "z2", True),
        ("rest", None, "rest", False),
        ("easy_run", 45, "z2", False),
        ("rest", None, "rest", False),
        ("long_run", 75, "z2", False),
    ]
    for day_index, (workout_type, duration_min, intensity, changed) in enumerate(plan_items):
        db_session.add(
            TrainingPlanItemModel(
                training_plan_id=plan.id,
                day_index=day_index,
                scheduled_date=plan.window_start + timedelta(days=day_index),
                workout_type=workout_type,
                duration_min=duration_min,
                intensity=intensity,
                changed=changed,
                change_reason="Reduce volume and delay quality session" if changed else None,
            )
        )

    for feature_key, value in {
        "average_pace_sec_per_km": 360.0,
        "positive_split_pct": 2.2,
        "heart_rate_drift_pct": 1.3,
    }.items():
        db_session.add(
            WorkoutDerivedFeatureModel(
                workout_session_id=workout.id,
                feature_key=feature_key,
                value_float=value,
                value_source="derived",
                availability_status="available",
                confidence_score=0.8,
            )
        )

    if include_feedback:
        feedback = PostWorkoutFeedbackModel(
            workout_session_id=workout.id,
            user_id=user_uuid,
            rpe=8,
            fatigue=4,
            soreness=2,
            breathing_load=3,
            confidence=4,
            free_text="前半程轻松，后半程腿有点重。",
        )
        db_session.add(feedback)
        db_session.flush()

        tags = (
            db_session.query(FeedbackTagModel)
            .filter(FeedbackTagModel.display_name.in_(["偏吃力", "腿沉"]))
            .all()
        )
        for tag in tags:
            db_session.add(PostWorkoutFeedbackTagLinkModel(feedback_id=feedback.id, tag_id=tag.id))

    db_session.commit()
    return SimpleNamespace(id=str(workout.id), user_id=user_id, snapshot_id=str(snapshot.id), plan_id=str(plan.id))


@pytest.fixture()
def analyzed_workout(db_session, imported_workout) -> SimpleNamespace:
    return _seed_analysis_bundle(db_session, imported_workout.id, imported_workout.user_id, include_feedback=False)


@pytest.fixture()
def analyzed_workout_with_feedback(db_session, imported_workout) -> SimpleNamespace:
    return _seed_analysis_bundle(db_session, imported_workout.id, imported_workout.user_id, include_feedback=True)
