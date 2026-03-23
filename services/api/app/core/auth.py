import base64
import json
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from domain.schemas import UserContext

from app.core.config import get_settings

bearer_scheme = HTTPBearer(auto_error=False)


def _decode_jwt_payload(token: str) -> dict:
    try:
        _, payload_b64, _ = token.split(".", 2)
        padding = "=" * (-len(payload_b64) % 4)
        payload_bytes = base64.urlsafe_b64decode(payload_b64 + padding)
        return json.loads(payload_bytes.decode())
    except Exception as exc:  # pragma: no cover - mapped to 401 below
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid bearer token",
        ) from exc


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> UserContext:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")

    payload = _decode_jwt_payload(credentials.credentials)
    sub_claim = get_settings().jwt_sub_claim
    subject = payload.get(sub_claim)

    if subject is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing subject claim")

    return UserContext(user_id=UUID(subject))
