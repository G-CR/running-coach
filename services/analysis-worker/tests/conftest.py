import importlib.util
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

WORKER_ROOT = Path(__file__).resolve().parents[1]
WORKER_APP_ROOT = WORKER_ROOT / "app"
DOMAIN_ROOT = Path(__file__).resolve().parents[3] / "packages" / "domain" / "src"
API_MODELS_PATH = WORKER_ROOT.parent / "api" / "app" / "db" / "models.py"

sys.path.insert(0, str(DOMAIN_ROOT))

def extend_package_path(package_name: str, extra_path: Path) -> None:
    module = sys.modules.get(package_name)
    if module is not None and hasattr(module, "__path__"):
        extra_path_str = str(extra_path)
        existing_paths = [path for path in list(module.__path__) if path != extra_path_str]
        module.__path__ = [extra_path_str, *existing_paths]


for worker_owned_module in [
    "app.core",
    "app.core.db",
    "app.engines",
    "app.engines.features",
    "app.engines.rules",
    "app.engines.planner",
    "app.engines.narrative",
    "app.jobs",
    "app.jobs.runner",
    "app.repos.workouts",
    "app.repos.plans",
]:
    sys.modules.pop(worker_owned_module, None)


if "app" in sys.modules and hasattr(sys.modules["app"], "__path__"):
    extend_package_path("app", WORKER_APP_ROOT)
    extend_package_path("app.engines", WORKER_APP_ROOT / "engines")
    extend_package_path("app.jobs", WORKER_APP_ROOT / "jobs")
    extend_package_path("app.repos", WORKER_APP_ROOT / "repos")
    extend_package_path("app.core", WORKER_APP_ROOT / "core")
else:
    sys.path.insert(0, str(WORKER_ROOT))


def load_api_models():
    spec = importlib.util.spec_from_file_location("worker_test_api_models", API_MODELS_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


@pytest.fixture()
def worker_db(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> SimpleNamespace:
    database_path = tmp_path / "analysis-worker.db"
    database_url = f"sqlite+pysqlite:///{database_path}"
    monkeypatch.setenv("DATABASE_URL", database_url)

    api_models = load_api_models()
    engine = create_engine(
        database_url,
        future=True,
        connect_args={"check_same_thread": False},
    )
    api_models.Base.metadata.create_all(engine)
    factory = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)

    try:
        from app.core import db as worker_db_module

        if hasattr(worker_db_module, "get_engine"):
            worker_db_module.get_engine.cache_clear()
        if hasattr(worker_db_module, "get_session_factory"):
            worker_db_module.get_session_factory.cache_clear()
    except ImportError:
        worker_db_module = None

    yield SimpleNamespace(factory=factory, models=api_models)

    if worker_db_module is not None:
        if hasattr(worker_db_module, "get_engine"):
            worker_db_module.get_engine.cache_clear()
        if hasattr(worker_db_module, "get_session_factory"):
            worker_db_module.get_session_factory.cache_clear()
    engine.dispose()
