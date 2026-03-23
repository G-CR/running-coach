from uuid import UUID

from app.engines.planner import PlanDecision


def write_analysis_snapshot(job_id: UUID, decision: PlanDecision, narrative: dict) -> bool:
    _ = (job_id, decision, narrative)
    return True
