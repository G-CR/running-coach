# AI Running Coach

Monorepo for the AI running coach MVP.

## Structure

- `apps/ios`: iPhone app
- `services/api`: FastAPI service
- `services/analysis-worker`: background analysis worker
- `packages/domain`: shared Python domain models
- `infra/supabase`: database migrations and seeds

## Local commands

- `make test-api`
- `make test-domain`
- `make ios-generate`

## Runbooks

- `docs/runbooks/local-dev.md`: local API / worker / iOS verification flow
- `docs/runbooks/reanalysis.md`: replay and reanalysis checklist
- `docs/fixtures/workouts/README.md`: golden workout fixtures used by tests
