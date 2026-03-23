from app.engines.features import FeatureSummary
from app.engines.planner import PlanDecision
from app.engines.rules import RuleResult


def render_narrative(features: FeatureSummary, rule_result: RuleResult, decision: PlanDecision) -> dict:
    return {
        "session_summary": f"Average pace {features.average_pace_sec_per_km:.1f}s/km, mode {rule_result.mode.value}.",
        "next_workout_reason": f"Next workout is {decision.next_workout.type} due to {', '.join(decision.reason_codes)}.",
        "week_adjustment_reason": "; ".join(decision.seven_day_adjustment.notes),
    }
