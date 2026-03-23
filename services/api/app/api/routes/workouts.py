from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from domain.schemas import UserContext, WorkoutImportPayload

from app.core.auth import get_current_user
from app.core.db import get_db_session
from app.services.workout_import import import_workout
from app.services.workout_queries import read_workout_detail, read_workout_list

router = APIRouter(prefix="/v1/workouts", tags=["workouts"])


@router.post("/import")
def post_workout_import(
    payload: WorkoutImportPayload,
    current_user: UserContext = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    sanitized_payload = payload.model_copy(update={"user_id": current_user.user_id})
    result = import_workout(session, current_user.user_id, sanitized_payload)
    status_code = status.HTTP_200_OK if result.deduplicated else status.HTTP_202_ACCEPTED
    return JSONResponse(status_code=status_code, content=result.model_dump(mode="json"))


@router.get("")
def get_workouts(
    current_user: UserContext = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    return {"items": read_workout_list(session, current_user.user_id)}


@router.get("/{workout_id}")
def get_workout_detail(
    workout_id: UUID,
    current_user: UserContext = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    detail = read_workout_detail(session, current_user.user_id, workout_id)
    if detail is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Workout not found")
    return detail
