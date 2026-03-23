from __future__ import annotations

import importlib.util
import os
import sys
from functools import lru_cache
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

REPO_ROOT = Path(__file__).resolve().parents[4]
API_MODELS_PATH = REPO_ROOT / "services" / "api" / "app" / "db" / "models.py"
API_MODELS_MODULE_NAME = "analysis_worker_api_models"


def get_database_url() -> str:
    return os.getenv("DATABASE_URL", "sqlite+pysqlite:///:memory:")


@lru_cache(maxsize=1)
def get_api_models():
    spec = importlib.util.spec_from_file_location(API_MODELS_MODULE_NAME, API_MODELS_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    sys.modules[API_MODELS_MODULE_NAME] = module
    spec.loader.exec_module(module)
    return module


@lru_cache(maxsize=1)
def get_engine():
    database_url = get_database_url()
    engine_kwargs: dict = {"future": True}

    if database_url.startswith("sqlite"):
        engine_kwargs["connect_args"] = {"check_same_thread": False}
        if database_url.endswith(":memory:"):
            engine_kwargs["poolclass"] = StaticPool

    engine = create_engine(database_url, **engine_kwargs)
    get_api_models().Base.metadata.create_all(engine)
    return engine


@lru_cache(maxsize=1)
def get_session_factory():
    return sessionmaker(bind=get_engine(), autoflush=False, autocommit=False, future=True)
