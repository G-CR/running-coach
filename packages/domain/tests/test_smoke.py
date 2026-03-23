import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))


def test_domain_package_importable():
    from domain.schemas import UserContext

    assert UserContext.model_fields["user_id"] is not None
