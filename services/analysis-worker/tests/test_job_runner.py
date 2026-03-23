from datetime import UTC, datetime, timedelta
from uuid import uuid4

from app.jobs.runner import process_analysis_job


def test_process_analysis_job_persists_snapshot_and_plan(worker_db):
    user_id = uuid4()
    workout_id = uuid4()
    prior_workout_id = uuid4()
    job_id = uuid4()
    started_at = datetime(2026, 3, 23, 6, 30, tzinfo=UTC)

    with worker_db.factory() as session:
        session.add(worker_db.models.UserModel(id=user_id))
        session.add(
            worker_db.models.GoalProfileCurrentModel(
                user_id=user_id,
                primary_goal_type="ten_k_improvement",
                target_time_sec=3000,
                weekly_run_days=4,
            )
        )
        session.add_all(
            [
                worker_db.models.WorkoutSessionModel(
                    id=prior_workout_id,
                    user_id=user_id,
                    source="healthkit",
                    source_workout_id="hk-prior-001",
                    started_at=started_at - timedelta(days=3),
                    ended_at=started_at - timedelta(days=3) + timedelta(minutes=55),
                    duration_sec=3300,
                    distance_m=12000,
                    avg_heart_rate=150,
                    max_heart_rate=167,
                    avg_cadence=170,
                    is_outdoor=True,
                    has_route=False,
                ),
                worker_db.models.WorkoutSessionModel(
                    id=workout_id,
                    user_id=user_id,
                    source="healthkit",
                    source_workout_id="hk-current-001",
                    started_at=started_at,
                    ended_at=started_at + timedelta(minutes=30),
                    duration_sec=1800,
                    distance_m=5000,
                    avg_heart_rate=148,
                    max_heart_rate=162,
                    avg_cadence=168,
                    is_outdoor=True,
                    has_route=True,
                ),
                worker_db.models.PostWorkoutFeedbackModel(
                    workout_session_id=workout_id,
                    user_id=user_id,
                    rpe=9,
                    fatigue=5,
                    soreness=4,
                    breathing_load=3,
                    confidence=3,
                    free_text="后半程腿沉。",
                ),
                worker_db.models.AnalysisJobModel(
                    id=job_id,
                    user_id=user_id,
                    workout_session_id=workout_id,
                    trigger="analyze",
                    status="queued",
                ),
            ]
        )
        session.add_all(
            [
                worker_db.models.WorkoutLapModel(
                    workout_session_id=workout_id,
                    lap_index=1,
                    distance_m=1000,
                    duration_sec=355,
                    avg_pace_sec_per_km=355,
                    avg_heart_rate=144,
                    avg_cadence=166,
                ),
                worker_db.models.WorkoutLapModel(
                    workout_session_id=workout_id,
                    lap_index=2,
                    distance_m=1000,
                    duration_sec=360,
                    avg_pace_sec_per_km=360,
                    avg_heart_rate=146,
                    avg_cadence=167,
                ),
                worker_db.models.WorkoutLapModel(
                    workout_session_id=workout_id,
                    lap_index=3,
                    distance_m=1000,
                    duration_sec=362,
                    avg_pace_sec_per_km=362,
                    avg_heart_rate=148,
                    avg_cadence=168,
                ),
                worker_db.models.WorkoutLapModel(
                    workout_session_id=workout_id,
                    lap_index=4,
                    distance_m=1000,
                    duration_sec=360,
                    avg_pace_sec_per_km=360,
                    avg_heart_rate=150,
                    avg_cadence=169,
                ),
                worker_db.models.WorkoutLapModel(
                    workout_session_id=workout_id,
                    lap_index=5,
                    distance_m=1000,
                    duration_sec=363,
                    avg_pace_sec_per_km=363,
                    avg_heart_rate=152,
                    avg_cadence=170,
                ),
            ]
        )
        session.commit()

    result = process_analysis_job(job_id)

    assert result.decision.next_workout.type == "recovery_run"
    assert result.snapshot_written is True

    with worker_db.factory() as session:
        job = session.get(worker_db.models.AnalysisJobModel, job_id)
        snapshot = session.query(worker_db.models.AnalysisSnapshotModel).filter_by(analysis_job_id=job_id).one()
        plan = session.query(worker_db.models.TrainingPlanModel).filter_by(user_id=user_id, is_current=True).one()
        items = (
            session.query(worker_db.models.TrainingPlanItemModel)
            .filter_by(training_plan_id=plan.id)
            .order_by(worker_db.models.TrainingPlanItemModel.day_index.asc())
            .all()
        )
        features = session.query(worker_db.models.WorkoutDerivedFeatureModel).filter_by(workout_session_id=workout_id).all()

    assert job.status == "succeeded"
    assert snapshot.mode == "protective"
    assert snapshot.input_summary["recent_load"]["last_7d_distance_m"] == 12000
    assert snapshot.decision_json["next_workout"]["type"] == "recovery_run"
    assert len(items) == 7
    assert items[0].workout_type == "recovery_run"
    assert items[0].changed is True
    assert {
        "average_pace_sec_per_km",
        "positive_split_pct",
        "heart_rate_drift_pct",
    }.issubset({feature.feature_key for feature in features})
