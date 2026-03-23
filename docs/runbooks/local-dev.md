# Local Development Runbook

## 1. Python environment

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
python3 -m venv .venv
source .venv/bin/activate
pip install -e packages/domain
pip install -e services/api
pip install -e services/analysis-worker
```

If the virtual environment already exists, reuse:

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
source .venv/bin/activate
```

## 2. Start the API locally

Use a file-backed SQLite database for repeatable local flows:

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
export DATABASE_URL="sqlite+pysqlite:///$(pwd)/.local-dev.db"
export PYTHONPATH="$(pwd)/packages/domain/src:$(pwd)/services/api"
.venv/bin/python -m uvicorn app.main:app --reload --app-dir services/api
```

Health checks:

```bash
curl http://127.0.0.1:8000/health
```

## 3. Run the worker locally

Use the same `DATABASE_URL` so the worker sees imported workouts and queued
analysis jobs.

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
export DATABASE_URL="sqlite+pysqlite:///$(pwd)/.local-dev.db"
export PYTHONPATH="$(pwd)/packages/domain/src:$(pwd)/services/analysis-worker"
.venv/bin/python -m app.main <analysis_job_id>
```

## 4. Run tests

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
.venv/bin/python -m pytest packages/domain/tests services/api/tests services/analysis-worker/tests -q
```

For iOS:

```bash
cd /Users/ws/Desktop/Running/ai-running-coach
xcodegen generate --spec apps/ios/project.yml
xcodebuild -project apps/ios/AIRunningCoach.xcodeproj \
  -scheme AIRunningCoach \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /Users/ws/Desktop/Running/ai-running-coach/.derived-data \
  test
```

## 5. Template fallback instead of LLM

The current worker path is rules + planner + template narrative only. If a real
LLM integration is added later, keep a switch that routes narrative generation
back to the local template renderer when:

- network access is unavailable;
- model credentials are missing;
- replay or regression tests need deterministic output.
