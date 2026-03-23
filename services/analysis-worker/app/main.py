from uuid import UUID
import sys

from app.jobs.runner import process_analysis_job


def main(job_id: str) -> None:
    process_analysis_job(UUID(job_id))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python -m app.main <analysis_job_id>")
    main(sys.argv[1])
