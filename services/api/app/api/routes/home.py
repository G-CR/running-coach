from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from domain.schemas import UserContext

from app.core.auth import get_current_user
from app.core.db import get_db_session
from app.services.home import read_home

router = APIRouter(prefix="/v1", tags=["home"])


@router.get("/home")
def get_home(
    current_user: UserContext = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    return read_home(session, current_user.user_id)
