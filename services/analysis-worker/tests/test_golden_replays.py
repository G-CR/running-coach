import pytest


REQUIRED_GOLDEN_FIXTURES = [
    "healthkit-5k-easy.json",
    "healthkit-8k-tempo.json",
    "healthkit-6x400-interval.json",
    "healthkit-18k-long-run.json",
    "healthkit-4k-recovery.json",
    "healthkit-missing-hr.json",
    "healthkit-10k-fatigued.json",
]


@pytest.mark.parametrize("fixture_name", REQUIRED_GOLDEN_FIXTURES)
def test_golden_fixture_replays_without_crashing(golden_runner, fixture_name):
    result = golden_runner.run(fixture_name)

    assert result.snapshot_written is True


def test_easy_run_fixture_produces_easy_or_recovery_next_workout(golden_runner):
    result = golden_runner.run("healthkit-5k-easy.json")

    assert result.decision.next_workout.type in {"easy_run", "recovery_run"}
    assert result.mode in {"standard", "conservative"}


def test_high_fatigue_fixture_never_schedules_interval(golden_runner):
    result = golden_runner.run("healthkit-10k-fatigued.json")

    assert result.decision.next_workout.type != "interval"
    assert result.mode == "protective"


def test_missing_data_fixture_falls_back_to_guardrailed_mode(golden_runner):
    result = golden_runner.run("healthkit-missing-hr.json")

    assert result.mode in {"degraded", "conservative"}
    assert result.decision.next_workout.type in {"easy_run", "recovery_run"}
