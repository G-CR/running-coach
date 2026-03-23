from collections.abc import Generator
from functools import lru_cache

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import get_settings
from app.db.models import Base


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
    return sessionmaker(bind=get_engine(), autoflush=False, autocommit=False, future=True)


def get_db_session() -> Generator[Session, None, None]:
    session = get_session_factory()()
    try:
        yield session
    finally:
        session.close()
