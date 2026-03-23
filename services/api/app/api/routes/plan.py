from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from domain.schemas import UserContext

from app.core.auth import get_current_user
from app.core.db import get_db_session
from app.services.plan_queries import read_current_plan

router = APIRouter(prefix="/v1", tags=["plan"])


@router.get("/plan")
def get_plan(
    days: int = Query(default=7, ge=1, le=14),
    current_user: UserContext = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    return read_current_plan(session, current_user.user_id, days=days)
