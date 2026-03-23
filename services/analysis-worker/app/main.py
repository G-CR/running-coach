from uuid import UUID

from app.jobs.runner import process_analysis_job


def main(job_id: str) -> None:
    process_analysis_job(UUID(job_id))
