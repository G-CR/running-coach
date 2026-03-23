from uuid import uuid4

from app.jobs.runner import process_analysis_job


def test_process_analysis_job_persists_snapshot_and_plan():
    job_id = uuid4()
    result = process_analysis_job(job_id)
    assert result.decision.next_workout.type in {"recovery_run", "easy_run"}
    assert result.snapshot_written is True
