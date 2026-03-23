import sys
from pathlib import Path

WORKER_ROOT = Path(__file__).resolve().parents[1]
WORKER_APP_ROOT = WORKER_ROOT / "app"
DOMAIN_ROOT = Path(__file__).resolve().parents[3] / "packages" / "domain" / "src"

sys.path.insert(0, str(DOMAIN_ROOT))

def extend_package_path(package_name: str, extra_path: Path) -> None:
    module = sys.modules.get(package_name)
    if module is not None and hasattr(module, "__path__"):
        extra_path_str = str(extra_path)
        existing_paths = [path for path in list(module.__path__) if path != extra_path_str]
        module.__path__ = [extra_path_str, *existing_paths]


for worker_owned_module in [
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
