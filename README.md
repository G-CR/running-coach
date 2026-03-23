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
