import base64
import json
import sys
from pathlib import Path
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

API_ROOT = Path(__file__).resolve().parents[1]
DOMAIN_ROOT = Path(__file__).resolve().parents[3] / "packages" / "domain" / "src"

sys.path.insert(0, str(API_ROOT))
sys.path.insert(0, str(DOMAIN_ROOT))

from app.main import app


def _b64url(value: dict) -> str:
    raw = json.dumps(value, separators=(",", ":")).encode()
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


@pytest.fixture()
def signed_token() -> str:
    header = {"alg": "none", "typ": "JWT"}
    payload = {"sub": str(uuid4())}
    return f"{_b64url(header)}.{_b64url(payload)}."


@pytest.fixture()
def auth_headers(signed_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {signed_token}"}


@pytest.fixture()
def client() -> TestClient:
    return TestClient(app)
