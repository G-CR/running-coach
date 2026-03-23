from uuid import UUID

from pydantic import BaseModel


class UserContext(BaseModel):
    user_id: UUID
