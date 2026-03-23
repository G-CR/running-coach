from uuid import UUID

from app.engines.features import AnalysisContext, PostWorkoutFeedback, RecentLoadSummary, WorkoutLap, WorkoutSummary


def load_analysis_context(job_id: UUID) -> AnalysisContext:
    seed = int(str(job_id.int)[-2:])
    fatigue = 5 if seed % 2 == 0 else 2
    return AnalysisContext(
        recent_load=RecentLoadSummary(last_7d_distance_m=42000 if fatigue == 5 else 24000, last_28d_distance_m=98000),
        feedback=PostWorkoutFeedback(rpe=9 if fatigue == 5 else 6, fatigue=fatigue, soreness=4 if fatigue == 5 else 1),
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
