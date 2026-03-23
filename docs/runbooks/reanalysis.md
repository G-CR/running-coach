# Reanalysis Runbook

## Goal

Re-run queued or targeted analysis jobs after feedback changes, rule updates,
or fixture regression checks.

## 1. Process a specific analysis job

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
export DATABASE_URL="sqlite+pysqlite:///$(pwd)/.local-dev.db"
export PYTHONPATH="$(pwd)/packages/domain/src:$(pwd)/services/analysis-worker"
.venv/bin/python -m app.main <analysis_job_id>
```

## 2. Inspect queued jobs

Use SQLite locally:

```bash
sqlite3 .local-dev.db "select id, trigger, status, created_at from analysis_jobs order by created_at;"
```

## 3. Replay golden fixtures

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
.venv/bin/python -m pytest services/analysis-worker/tests/test_golden_replays.py -q
```

This is the fastest way to catch regressions where high-fatigue or low-signal
inputs drift toward aggressive next-workout advice.

## 4. When to prefer template fallback

If a future LLM-backed narrative layer fails, replay checks should still pass.
Use the template fallback when:

- API keys are absent;
- the external model is unstable;
- you need deterministic release validation.

## 5. Expected release gate

Before a release candidate or personal-use build:

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
.venv/bin/python -m pytest packages/domain/tests services/api/tests services/analysis-worker/tests -q
xcodegen generate --spec apps/ios/project.yml
xcodebuild -project apps/ios/AIRunningCoach.xcodeproj \
  -scheme AIRunningCoach \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /Users/ws/Desktop/Running/ai-running-coach/.derived-data \
  test
```
