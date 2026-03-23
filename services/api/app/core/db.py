from collections.abc import Generator
from functools import lru_cache

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import get_settings
from app.db.models import Base, FeedbackTagModel

DEFAULT_FEEDBACK_TAGS = [
    {"tag_key": "easy_feel", "display_name": "偏轻松", "category": "intensity", "sort_order": 10},
    {"tag_key": "just_right", "display_name": "合适", "category": "intensity", "sort_order": 20},
    {"tag_key": "hard_feel", "display_name": "偏吃力", "category": "intensity", "sort_order": 30},
    {"tag_key": "very_hard", "display_name": "非常吃力", "category": "intensity", "sort_order": 40},
    {"tag_key": "heavy_legs", "display_name": "腿沉", "category": "body", "sort_order": 50},
    {"tag_key": "cardio_stress", "display_name": "心肺压力大", "category": "body", "sort_order": 60},
]


def seed_feedback_tags(factory) -> None:
    session = factory()
    try:
        existing = session.query(FeedbackTagModel).count()
        if existing == 0:
            session.add_all(FeedbackTagModel(**tag) for tag in DEFAULT_FEEDBACK_TAGS)
            session.commit()
    finally:
        session.close()


@lru_cache(maxsize=1)
def get_engine():
    database_url = get_settings().database_url
    engine_kwargs: dict = {"future": True}

    if database_url.startswith("sqlite"):
        engine_kwargs["connect_args"] = {"check_same_thread": False}
        if database_url.endswith(":memory:"):
            engine_kwargs["poolclass"] = StaticPool

    engine = create_engine(database_url, **engine_kwargs)
    Base.metadata.create_all(engine)
    return engine


@lru_cache(maxsize=1)
def get_session_factory():
    factory = sessionmaker(bind=get_engine(), autoflush=False, autocommit=False, future=True)
    seed_feedback_tags(factory)
    return factory


def get_db_session() -> Generator[Session, None, None]:
    session = get_session_factory()()
    try:
        yield session
    finally:
        session.close()
