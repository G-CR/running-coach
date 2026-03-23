from pydantic import BaseModel
from uuid import UUID

from app.core.db import get_session_factory
from app.engines.features import AnalysisContext, compute_features
from app.engines.narrative import render_narrative
from app.engines.planner import PlanDecision, build_plan
from app.engines.rules import RuleResult, evaluate_rules
from app.repos.plans import write_analysis_snapshot
from app.repos.workouts import load_analysis_context, update_job_status
from domain.enums import AnalysisJobStatus


class JobProcessingResult(BaseModel):
    decision: PlanDecision
    snapshot_written: bool


def process_analysis_job(job_id: UUID, context: AnalysisContext | None = None) -> JobProcessingResult:
    session = get_session_factory()()
    try:
        update_job_status(session, job_id, AnalysisJobStatus.RUNNING)
        resolved_context = context or load_analysis_context(session, job_id)
        features = compute_features(resolved_context)
        rule_result: RuleResult = evaluate_rules(resolved_context)
        decision = build_plan(resolved_context, rule_result, features)
        narrative = render_narrative(features, rule_result, decision)
        snapshot_written = write_analysis_snapshot(
            session,
            job_id,
            resolved_context,
            features,
            rule_result,
            decision,
            narrative,
        )
        update_job_status(session, job_id, AnalysisJobStatus.SUCCEEDED)
        session.commit()
        return JobProcessingResult(decision=decision, snapshot_written=snapshot_written)
    except Exception as exc:
        session.rollback()
        try:
            update_job_status(session, job_id, AnalysisJobStatus.FAILED, str(exc))
            session.commit()
        except Exception:
            session.rollback()
        raise
    finally:
        session.close()
