import json
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
FIXTURE_ROOT = REPO_ROOT / "docs" / "fixtures" / "workouts"
PROJECT_PYTHON = REPO_ROOT / ".venv" / "bin" / "python"


def test_import_feedback_worker_and_home_flow(tmp_path):
    database_url = f"sqlite+pysqlite:///{tmp_path / 'api-e2e.db'}"
    fixture_path = FIXTURE_ROOT / "healthkit-10k-fatigued.json"

    script = f"""
import base64
import json
import os
import subprocess
import sys
from pathlib import Path
from uuid import uuid4

from fastapi.testclient import TestClient

REPO_ROOT = Path({str(REPO_ROOT)!r})
API_ROOT = REPO_ROOT / "services" / "api"
WORKER_ROOT = REPO_ROOT / "services" / "analysis-worker"
DOMAIN_ROOT = REPO_ROOT / "packages" / "domain" / "src"
FIXTURE_PATH = Path({str(fixture_path)!r})

sys.path.insert(0, str(DOMAIN_ROOT))
sys.path.insert(0, str(API_ROOT))

from app.core import db as api_db
from app.db.models import AnalysisJobModel
from app.main import app


def b64url(value: dict) -> str:
    raw = json.dumps(value, separators=(",", ":")).encode()
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def run_analysis_job(job_id: str) -> None:
    env = os.environ.copy()
    env["DATABASE_URL"] = os.environ["DATABASE_URL"]
    env["PYTHONPATH"] = os.pathsep.join([str(WORKER_ROOT), str(DOMAIN_ROOT)])
    subprocess.run(
        [sys.executable, "-m", "app.main", job_id],
        cwd=WORKER_ROOT,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )


user_id = str(uuid4())
token = f"{{b64url({{'alg': 'none', 'typ': 'JWT'}})}}.{{b64url({{'sub': user_id}})}}."
headers = {{"Authorization": f"Bearer {{token}}"}}

api_db.get_engine.cache_clear()
api_db.get_session_factory.cache_clear()

payload = json.loads(FIXTURE_PATH.read_text())
payload["user_id"] = user_id

with TestClient(app) as client:
    import_response = client.post("/v1/workouts/import", json=payload, headers=headers)
    workout_id = import_response.json()["workout_id"]
    feedback_response = client.post(
        f"/v1/workouts/{{workout_id}}/feedback",
        json={{
            "rpe": 9,
            "fatigue": 5,
            "soreness": 4,
            "breathing_load": 4,
            "confidence": 3,
            "selected_tags": ["偏吃力", "腿沉"],
            "free_text": "最后两公里明显发沉，恢复需求高。",
        }},
        headers=headers,
    )

    with api_db.get_session_factory()() as session:
        job_ids = [
            str(job.id)
            for job in session.query(AnalysisJobModel)
            .filter_by(status="queued")
            .order_by(AnalysisJobModel.created_at.asc())
            .all()
        ]

    for job_id in job_ids:
        run_analysis_job(job_id)

    home_response = client.get("/v1/home", headers=headers)
    print(
        json.dumps(
            {{
                "import_status": import_response.status_code,
                "feedback_status": feedback_response.status_code,
                "home_status": home_response.status_code,
                "home_body": home_response.json(),
            }},
            ensure_ascii=False,
        )
    )
"""

    env = os.environ.copy()
    env["DATABASE_URL"] = database_url
    result = subprocess.run(
        [str(PROJECT_PYTHON), "-c", script],
        cwd=REPO_ROOT,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )

    output = json.loads(result.stdout.strip())
    assert output["import_status"] == 202
    assert output["feedback_status"] == 202
    assert output["home_status"] == 200

    body = output["home_body"]
    assert body["next_workout"]["type"] == "recovery_run"
    assert body["latest_workout_summary"]["analysis_mode"] == "protective"
    assert body["plan_change_summary"]["changed_items"] >= 1
    assert body["todos"]["needs_feedback"] is False
    assert body["todos"]["sync_pending"] is False
