# Workout Golden Fixtures

These JSON files are reusable workout fixtures for API import tests and
analysis-worker golden replay tests.

Included samples:

- `healthkit-5k-easy.json`
- `healthkit-8k-tempo.json`
- `healthkit-6x400-interval.json`
- `healthkit-18k-long-run.json`
- `healthkit-4k-recovery.json`
- `healthkit-missing-hr.json`
- `healthkit-10k-fatigued.json`

Rules:

- Top-level fields stay compatible with `WorkoutImportPayload` so the same
  file can be POSTed to `/v1/workouts/import`.
- Extra replay-only context lives inside `raw_payload.golden_context`.
- `golden_context.feedback` seeds post-workout feedback for worker replay.
- `golden_context.prior_workouts` seeds recent-load history for worker replay.

When adding a new fixture, keep it small, deterministic, and representative of
one clear scenario.
