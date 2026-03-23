from datetime import UTC, datetime
from uuid import uuid4
import sys
from pathlib import Path

import pytest
from pydantic import ValidationError

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from domain.schemas import WorkoutImportPayload


def test_workout_import_payload_requires_source_workout_id():
    with pytest.raises(ValidationError):
        WorkoutImportPayload(
            user_id=uuid4(),
            source="healthkit",
            source_workout_id="",
            started_at=datetime.now(UTC),
            ended_at=datetime.now(UTC),
            duration_sec=1800,
            distance_m=5000,
        )
