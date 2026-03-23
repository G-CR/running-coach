from uuid import UUID

from pydantic import BaseModel

from app.engines.features import AnalysisContext, compute_features
from app.engines.narrative import render_narrative
from app.engines.planner import PlanDecision, build_plan
from app.engines.rules import RuleResult, evaluate_rules
from app.repos.plans import write_analysis_snapshot
from app.repos.workouts import load_analysis_context


class JobProcessingResult(BaseModel):
    decision: PlanDecision
    snapshot_written: bool


def process_analysis_job(job_id: UUID, context: AnalysisContext | None = None) -> JobProcessingResult:
    resolved_context = context or load_analysis_context(job_id)
    features = compute_features(resolved_context)
    rule_result: RuleResult = evaluate_rules(resolved_context)
    decision = build_plan(resolved_context, rule_result, features)
    narrative = render_narrative(features, rule_result, decision)
    snapshot_written = write_analysis_snapshot(job_id, decision, narrative)
    return JobProcessingResult(decision=decision, snapshot_written=snapshot_written)
