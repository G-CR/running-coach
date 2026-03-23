import importlib.util
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
from types import SimpleNamespace
from uuid import UUID, uuid4

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

WORKER_ROOT = Path(__file__).resolve().parents[1]
WORKER_APP_ROOT = WORKER_ROOT / "app"
DOMAIN_ROOT = Path(__file__).resolve().parents[3] / "packages" / "domain" / "src"
FIXTURE_ROOT = Path(__file__).resolve().parents[3] / "docs" / "fixtures" / "workouts"
API_MODELS_PATH = WORKER_ROOT.parent / "api" / "app" / "db" / "models.py"

sys.path.insert(0, str(DOMAIN_ROOT))

def extend_package_path(package_name: str, extra_path: Path) -> None:
    module = sys.modules.get(package_name)
    if module is not None and hasattr(module, "__path__"):
        extra_path_str = str(extra_path)
        existing_paths = [path for path in list(module.__path__) if path != extra_path_str]
        module.__path__ = [extra_path_str, *existing_paths]


for worker_owned_module in [
    "app.core",
    "app.core.db",
    "app.engines",
    "app.engines.features",
    "app.engines.rules",
    "app.engines.planner",
    "app.engines.narrative",
    "app.jobs",
    "app.jobs.runner",
    "app.repos.workouts",
    "app.repos.plans",
]:
    sys.modules.pop(worker_owned_module, None)


if "app" in sys.modules and hasattr(sys.modules["app"], "__path__"):
    extend_package_path("app", WORKER_APP_ROOT)
    extend_package_path("app.engines", WORKER_APP_ROOT / "engines")
    extend_package_path("app.jobs", WORKER_APP_ROOT / "jobs")
    extend_package_path("app.repos", WORKER_APP_ROOT / "repos")
    extend_package_path("app.core", WORKER_APP_ROOT / "core")
else:
    sys.path.insert(0, str(WORKER_ROOT))


def load_api_models():
    spec = importlib.util.spec_from_file_location("worker_test_api_models", API_MODELS_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


@pytest.fixture()
def worker_db(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> SimpleNamespace:
    database_path = tmp_path / "analysis-worker.db"
    database_url = f"sqlite+pysqlite:///{database_path}"
    monkeypatch.setenv("DATABASE_URL", database_url)

    api_models = load_api_models()
    engine = create_engine(
        database_url,
        future=True,
        connect_args={"check_same_thread": False},
    )
    api_models.Base.metadata.create_all(engine)
    factory = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)

    try:
        from app.core import db as worker_db_module

        if hasattr(worker_db_module, "get_engine"):
            worker_db_module.get_engine.cache_clear()
        if hasattr(worker_db_module, "get_session_factory"):
            worker_db_module.get_session_factory.cache_clear()
    except ImportError:
        worker_db_module = None

    yield SimpleNamespace(factory=factory, models=api_models)

    if worker_db_module is not None:
        if hasattr(worker_db_module, "get_engine"):
            worker_db_module.get_engine.cache_clear()
        if hasattr(worker_db_module, "get_session_factory"):
            worker_db_module.get_session_factory.cache_clear()
    engine.dispose()


def _parse_datetime(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _load_fixture_payload(name: str) -> dict:
    return json.loads((FIXTURE_ROOT / name).read_text())


def _seed_workout_session(session, models, user_id: UUID, payload: dict, source_workout_id: str, started_at: datetime):
    ended_at = _parse_datetime(payload["ended_at"]) if payload.get("ended_at") else started_at + timedelta(seconds=payload["duration_sec"])
    workout = models.WorkoutSessionModel(
        id=uuid4(),
        user_id=user_id,
        source=payload["source"],
        source_workout_id=source_workout_id,
        started_at=started_at,
        ended_at=ended_at,
        duration_sec=payload["duration_sec"],
        distance_m=payload["distance_m"],
        avg_heart_rate=payload.get("avg_heart_rate"),
        max_heart_rate=payload.get("max_heart_rate"),
        avg_cadence=payload.get("avg_cadence"),
        is_outdoor=payload.get("is_outdoor", True),
        has_route=payload.get("has_route", False),
    )
    session.add(workout)
    session.flush()
    return workout


@pytest.fixture()
def golden_runner(worker_db):
    from app.jobs.runner import process_analysis_job

    class GoldenRunner:
        def run(self, fixture_name: str) -> SimpleNamespace:
            payload = _load_fixture_payload(fixture_name)
            raw_payload = payload.get("raw_payload") or {}
            golden_context = raw_payload.get("golden_context") or {}
            user_id = UUID(payload["user_id"])
            workout_started_at = _parse_datetime(payload["started_at"])

            with worker_db.factory() as session:
                session.add(worker_db.models.UserModel(id=user_id))
                goal = golden_context.get("goal") or {}
                session.add(
                    worker_db.models.GoalProfileCurrentModel(
                        user_id=user_id,
                        primary_goal_type=goal.get("primary_goal_type", "ten_k_improvement"),
                        target_time_sec=goal.get("target_time_sec", 3000),
                        weekly_run_days=goal.get("weekly_run_days", 4),
                    )
                )

                for index, prior in enumerate(golden_context.get("prior_workouts", []), start=1):
                    prior_started_at = _parse_datetime(prior["started_at"])
                    prior_payload = {
                        **payload,
                        "duration_sec": prior["duration_sec"],
                        "distance_m": prior["distance_m"],
                        "avg_heart_rate": prior.get("avg_heart_rate"),
                        "max_heart_rate": prior.get("max_heart_rate"),
                        "avg_cadence": prior.get("avg_cadence"),
                        "ended_at": prior.get("ended_at", prior["started_at"]),
                    }
                    _seed_workout_session(
                        session,
                        worker_db.models,
                        user_id,
                        prior_payload,
                        prior.get("source_workout_id", f"{payload['source_workout_id']}-prior-{index}"),
                        prior_started_at,
                    )

                workout = _seed_workout_session(
                    session,
                    worker_db.models,
                    user_id,
                    payload,
                    payload["source_workout_id"],
                    workout_started_at,
                )

                for lap in payload.get("laps", []):
                    session.add(
                        worker_db.models.WorkoutLapModel(
                            workout_session_id=workout.id,
                            lap_index=lap["lap_index"],
                            distance_m=lap["distance_m"],
                            duration_sec=lap["duration_sec"],
                            avg_pace_sec_per_km=lap.get("avg_pace_sec_per_km"),
                            avg_heart_rate=lap.get("avg_heart_rate"),
                            avg_cadence=lap.get("avg_cadence"),
                        )
                    )

                feedback = golden_context.get("feedback")
                if feedback is not None:
                    session.add(
                        worker_db.models.PostWorkoutFeedbackModel(
                            workout_session_id=workout.id,
                            user_id=user_id,
                            rpe=feedback.get("rpe"),
                            fatigue=feedback.get("fatigue"),
                            soreness=feedback.get("soreness"),
                            breathing_load=feedback.get("breathing_load"),
                            confidence=feedback.get("confidence"),
                            free_text=feedback.get("free_text"),
                        )
                    )

                job = worker_db.models.AnalysisJobModel(
                    id=uuid4(),
                    user_id=user_id,
                    workout_session_id=workout.id,
                    trigger=golden_context.get("trigger", "analyze"),
                    status="queued",
                )
                session.add(job)
                session.flush()
                job_id = job.id
                session.commit()

            result = process_analysis_job(job_id)

            with worker_db.factory() as session:
                snapshot = (
                    session.query(worker_db.models.AnalysisSnapshotModel)
                    .filter_by(analysis_job_id=job_id)
                    .one()
                )

            return SimpleNamespace(
                decision=result.decision,
                snapshot_written=result.snapshot_written,
                mode=snapshot.mode,
                analysis_job_id=str(job_id),
            )

    return GoldenRunner()
