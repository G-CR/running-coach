from app.engines.features import AnalysisContext, PostWorkoutFeedback, RecentLoadSummary, WorkoutLap, WorkoutSummary, compute_features


def test_compute_features_returns_basic_pace_and_split_metrics():
    context = AnalysisContext(
        recent_load=RecentLoadSummary(last_7d_distance_m=22000, last_28d_distance_m=76000),
        feedback=PostWorkoutFeedback(rpe=6, fatigue=2, soreness=1),
        workout=WorkoutSummary(
            distance_m=10000,
            duration_sec=3300,
            avg_heart_rate=158,
            laps=[
                WorkoutLap(lap_index=1, duration_sec=1600, distance_m=5000),
                WorkoutLap(lap_index=2, duration_sec=1700, distance_m=5000),
            ],
        ),
    )

    features = compute_features(context)

    assert round(features.average_pace_sec_per_km, 1) == 330.0
    assert features.positive_split_pct > 0
