from datetime import UTC, datetime, timedelta
from uuid import uuid4
import sys
from pathlib import Path

import pytest
from sqlalchemy import create_engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from app.db.models import Base, WorkoutSessionModel


def insert_workout_session(db_session, user_id, source, source_workout_id):
    started_at = datetime.now(UTC)
    db_session.add(
        WorkoutSessionModel(
            id=uuid4(),
            user_id=user_id,
            source=source,
            source_workout_id=source_workout_id,
            started_at=started_at,
            ended_at=started_at + timedelta(minutes=30),
            duration_sec=1800,
            distance_m=5000,
        )
    )
    db_session.commit()


@pytest.fixture()
def db_session():
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(engine)
    session = sessionmaker(bind=engine, future=True)()
    try:
        yield session
    finally:
        session.close()


def test_workout_session_unique_constraint(db_session):
    user_id = uuid4()

    insert_workout_session(db_session, user_id=user_id, source="healthkit", source_workout_id="abc")

    with pytest.raises(IntegrityError):
        insert_workout_session(db_session, user_id=user_id, source="healthkit", source_workout_id="abc")
