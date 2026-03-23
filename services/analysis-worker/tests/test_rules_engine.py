from app.engines.features import AnalysisContext, PostWorkoutFeedback, RecentLoadSummary, WorkoutSummary
from app.engines.rules import evaluate_rules
from domain.enums import AnalysisMode


def test_rules_engine_enters_protective_mode_when_fatigue_is_high():
    context = AnalysisContext(
        recent_load=RecentLoadSummary(last_7d_distance_m=42000, last_28d_distance_m=98000),
        feedback=PostWorkoutFeedback(rpe=9, fatigue=5, soreness=4),
        workout=WorkoutSummary(distance_m=10000, duration_sec=3300),
    )
    result = evaluate_rules(context)
    assert result.mode == AnalysisMode.PROTECTIVE
