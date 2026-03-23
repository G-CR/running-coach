from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from domain.schemas import UserContext

from app.core.auth import get_current_user
from app.core.db import get_db_session
from app.services.feedback import FeedbackPayload, submit_feedback

router = APIRouter(prefix="/v1/workouts", tags=["feedback"])


@router.post("/{workout_id}/feedback")
def post_feedback(
    workout_id: UUID,
    payload: FeedbackPayload,
    current_user: UserContext = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    try:
        result = submit_feedback(session, current_user.user_id, workout_id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    return JSONResponse(status_code=status.HTTP_202_ACCEPTED, content=result.model_dump(mode="json"))
