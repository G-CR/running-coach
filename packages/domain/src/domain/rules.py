from pydantic import BaseModel

from .enums import AnalysisMode


class RuleEvaluationResult(BaseModel):
    mode: AnalysisMode
    reason_codes: list[str] = []
