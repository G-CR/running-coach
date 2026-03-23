import base64
import json
import sys
from pathlib import Path
from types import SimpleNamespace
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

API_ROOT = Path(__file__).resolve().parents[1]
DOMAIN_ROOT = Path(__file__).resolve().parents[3] / "packages" / "domain" / "src"
REPO_ROOT = Path(__file__).resolve().parents[3]
FIXTURE_ROOT = REPO_ROOT / "docs" / "fixtures" / "workouts"

sys.path.insert(0, str(API_ROOT))
sys.path.insert(0, str(DOMAIN_ROOT))

from app.main import app


def _b64url(value: dict) -> str:
    raw = json.dumps(value, separators=(",", ":")).encode()
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


@pytest.fixture()
def user_id() -> str:
    return str(uuid4())


@pytest.fixture()
def signed_token(user_id: str) -> str:
    header = {"alg": "none", "typ": "JWT"}
    payload = {"sub": user_id}
    return f"{_b64url(header)}.{_b64url(payload)}."


@pytest.fixture()
def auth_headers(signed_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {signed_token}"}


@pytest.fixture()
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture()
def healthkit_payload(user_id: str) -> dict:
    payload = json.loads((FIXTURE_ROOT / "healthkit-5k-easy.json").read_text())
    payload["user_id"] = user_id
    return payload


@pytest.fixture()
def imported_workout(client: TestClient, auth_headers: dict[str, str], healthkit_payload: dict) -> SimpleNamespace:
    response = client.post("/v1/workouts/import", json=healthkit_payload, headers=auth_headers)
    body = response.json()
    return SimpleNamespace(id=body["workout_id"])
