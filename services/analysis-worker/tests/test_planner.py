from app.engines.features import AnalysisContext, FeatureSummary, PostWorkoutFeedback, RecentLoadSummary, WorkoutSummary
from app.engines.planner import build_plan
from app.engines.rules import RuleResult
from domain.enums import AnalysisMode


def test_planner_returns_recovery_run_after_protective_mode():
    context = AnalysisContext(
        recent_load=RecentLoadSummary(last_7d_distance_m=42000, last_28d_distance_m=98000),
        feedback=PostWorkoutFeedback(rpe=9, fatigue=5, soreness=4),
        workout=WorkoutSummary(distance_m=10000, duration_sec=3300),
    )
    decision = build_plan(
        context=context,
        rule_result=RuleResult(mode=AnalysisMode.PROTECTIVE, reason_codes=["high_fatigue"]),
        features=FeatureSummary(average_pace_sec_per_km=330, positive_split_pct=3.0, heart_rate_drift_pct=4.5),
    )
    assert decision.next_workout.type == "recovery_run"
    assert decision.seven_day_adjustment.changed is True
