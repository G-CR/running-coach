from pydantic import BaseModel, Field

from domain.enums import AnalysisMode

from app.engines.features import AnalysisContext, FeatureSummary
from app.engines.rules import RuleResult


class NextWorkout(BaseModel):
    type: str
    duration_min: int
    intensity: str


class SevenDayAdjustment(BaseModel):
    changed: bool
    notes: list[str] = Field(default_factory=list)


class PlanDecision(BaseModel):
    next_workout: NextWorkout
    seven_day_adjustment: SevenDayAdjustment
    reason_codes: list[str] = Field(default_factory=list)


def build_plan(context: AnalysisContext, rule_result: RuleResult, features: FeatureSummary) -> PlanDecision:
    if rule_result.mode == AnalysisMode.PROTECTIVE:
        return PlanDecision(
            next_workout=NextWorkout(type="recovery_run", duration_min=35, intensity="z1-z2"),
            seven_day_adjustment=SevenDayAdjustment(changed=True, notes=["Reduce volume and delay quality session"]),
            reason_codes=rule_result.reason_codes,
        )

    if rule_result.mode in {AnalysisMode.CONSERVATIVE, AnalysisMode.DEGRADED}:
        return PlanDecision(
            next_workout=NextWorkout(type="easy_run", duration_min=40, intensity="z2"),
            seven_day_adjustment=SevenDayAdjustment(changed=True, notes=["Keep the next week conservative"]),
            reason_codes=rule_result.reason_codes,
        )

    return PlanDecision(
        next_workout=NextWorkout(type="easy_run", duration_min=45, intensity="z2"),
        seven_day_adjustment=SevenDayAdjustment(changed=False, notes=["Keep current plan"]),
        reason_codes=rule_result.reason_codes,
    )
