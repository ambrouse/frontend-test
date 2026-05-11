# Plan: Fix Provider Install/Run (Real) + Hub Low-Latency

## Timestamp
- Created: 2026-05-11 (Asia/Saigon)

## Goal
- Fix real install/run lifecycle for:
  - `agentic-commerce-blueprint`
  - `multi-agent-intelligent-warehouse`
- Validate with real API requests (non-dry-run) and repeat until lifecycle is stable.
- Ensure no fallback branch in Hub wrappers; use main branch and real LLM-related runtime path from provider source.
- Reduce `/hub` card load latency with cache strategy + refresh behavior when provider data changes.

## Success Criteria
- Install/Run/Stop/Delete for both providers complete via real backend HTTP requests without script failure.
- Deploy directories are created correctly and reused safely on rerun.
- Runtime status/log/metrics files are updated correctly after each action.
- `/hub` data path has low-latency fetch and cache invalidation when providers change.
- Backend + frontend test/build checks pass.

## Skills Used
- `plan-skill`: planning phases and execution discipline.
- `backend-skill`: backend/provider runtime fixes.
- `frontend-skill`: `/hub` performance and cache update behavior.
- `documentation-skill`: write execution summary doc in `docs/`.
- `logging-skill`: write task log in `logs/`.

## Resources Needed
- Docker daemon running.
- Git access to upstream provider repos.
- NVIDIA API key in local environment.
- Python venv + Node modules already installed.

## Phase Plan

### Phase 1: Baseline and Reproduce (45-75 min)
- Start backend service locally.
- Execute real HTTP requests for install/run/stop/delete for each provider.
- Capture task states, runtime logs, and failure traces.
- Identify root causes in:
  - backend runtime orchestration,
  - provider wrappers (Windows/Linux),
  - provider source repo assumptions.

### Phase 2: Fix Hub Wrapper and Runtime Integration (60-120 min)
- Patch provider scripts/manifests/backend orchestration for deterministic deploy path and repeatable reruns.
- Ensure install step always leaves provider in runnable state.
- Handle idempotency for partially-created deploy directories and previously failed runs.
- Add/adjust backend tests for the discovered failure modes.

### Phase 3: If Upstream Provider Source Requires Changes (90-240 min)
- Clone affected provider source into `deploy/`.
- Patch source runtime/config issues needed for Hub integration.
- Validate locally with real compose run path.
- If permission is available, push upstream fixes to provider GitHub (or document exact patch if push is blocked).

### Phase 4: Hub Latency and Cache Update (45-90 min)
- Audit `/hub` API and frontend loading path.
- Optimize cache policy for provider list/featured/detail.
- Ensure cache refreshes immediately when provider state changes (install/run/stop/delete).
- Verify UI render responsiveness and no stale cards.

### Phase 5: Full Verification Loop (60-120 min)
- Run repeated lifecycle loops on both providers:
  - install -> run -> health/metrics/log checks -> stop -> delete
- Repeat until stable pass.
- Run backend tests and frontend checks/build.

### Phase 6: Documentation + Logs (20-40 min)
- Write summary in `docs/`:
  - root causes,
  - fixes,
  - real test evidence,
  - known limits.
- Write detailed execution log in `logs/` with timestamps and command outcomes.

## Risk Notes
- Upstream provider repos may change and break compose/scripts.
- Full runtime start can be resource heavy and time-consuming.
- Upstream push may be blocked by repository permissions/credentials.

## Execution Policy
- Execute phases sequentially.
- Do not stop until all feasible fixes and validations are complete for this session.
- If blocked by external permissions/infrastructure, record exact blocker and continue with all remaining local fixes and validations.
