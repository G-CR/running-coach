from pydantic import BaseModel, Field

from domain.enums import AnalysisMode

from app.engines.features import AnalysisContext


class RuleResult(BaseModel):
    mode: AnalysisMode
    reason_codes: list[str] = Field(default_factory=list)


def evaluate_rules(context: AnalysisContext) -> RuleResult:
    if (context.feedback.fatigue or 0) >= 5 or (context.feedback.rpe or 0) >= 9 or (context.feedback.soreness or 0) >= 4:
        return RuleResult(mode=AnalysisMode.PROTECTIVE, reason_codes=["high_fatigue"])

    if context.recent_load.last_7d_distance_m >= 35000 or (context.feedback.fatigue or 0) >= 3:
        return RuleResult(mode=AnalysisMode.CONSERVATIVE, reason_codes=["elevated_load"])

    if context.workout.avg_heart_rate is None:
        return RuleResult(mode=AnalysisMode.DEGRADED, reason_codes=["missing_hr"])

    return RuleResult(mode=AnalysisMode.STANDARD, reason_codes=["balanced"])
