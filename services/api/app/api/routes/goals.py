from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from domain.schemas import UserContext

from app.core.auth import get_current_user
from app.core.db import get_db_session
from app.services.goals import GoalUpdatePayload, GoalUpdateResult, read_current_goal, update_current_goal

router = APIRouter(prefix="/v1/goals", tags=["goals"])


@router.get("/current", response_model=GoalUpdateResult)
def get_current_goal(
    current_user: UserContext = Depends(get_current_user),
    session: Session = Depends(get_db_session),
) -> GoalUpdateResult:
    result = read_current_goal(session, current_user.user_id)
    if result is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
    return result


@router.post("/current", response_model=GoalUpdateResult)
def post_current_goal(
    payload: GoalUpdatePayload,
    current_user: UserContext = Depends(get_current_user),
    session: Session = Depends(get_db_session),
) -> GoalUpdateResult:
    return update_current_goal(session, current_user.user_id, payload)
