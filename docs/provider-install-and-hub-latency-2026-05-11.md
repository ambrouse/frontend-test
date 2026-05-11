# Provider Install/Run + Hub Latency Report

## Timestamp
- Date: 2026-05-11 (Asia/Saigon)

## Scope
- Fix real lifecycle reliability for:
  - `agentic-commerce-blueprint`
  - `multi-agent-intelligent-warehouse`
- Reduce `/hub` loading/scroll latency and improve provider-card data freshness.

## Root Causes Found
- `run` could fail with `deploy directory missing; install first` when users triggered run before install/deploy existed.
- Provider setup scripts were not resilient when deploy directory existed but was not a valid git clone (partial/leftover state).
- Agentic runtime could fail from strict compose `--wait` behavior due transient/secondary service health (observability container), even when core gateway became healthy.
- Provider registry refresh scanned too often (`ttl=2s`), adding overhead on hub data reads.

## Fixes Applied
- Backend orchestration:
  - `run` now auto-runs `setup` first when deploy is missing (real run only).
  - Provider registry refresh after lifecycle/config updates is forced and immediate.
  - Registry read TTL increased to reduce repeated expensive scans.
- Provider scripts:
  - Windows/Linux setup scripts now handle non-git/non-empty deploy directories safely before clone.
  - Setup update path now fetch/checkout/pull target branch explicitly.
  - Agentic run scripts now:
    - `docker compose up -d` (not strict compose wait gate),
    - wait on real gateway health endpoint `http://127.0.0.1:<port>/api/health`,
    - then execute Milvus seeder.
- Hub frontend:
  - Added session cache (`sessionStorage`) for providers/featured data with stale-while-revalidate flow.
  - Added hub-scoped performance mode to reduce heavy visual effects during scroll.
- Hub backend cache freshness:
  - `cacheVersion` increments immediately after lifecycle changes via forced refresh.

## Real Validation (Non-Dry-Run)
- Backend instance on `http://127.0.0.1:18000`.
- Real request lifecycle loops passed for both providers:
  - `install -> run -> stop -> delete` = all `completed`.
- Direct `run` without prior install:
  - `multi-agent-intelligent-warehouse`: passed (auto-setup then run).
  - `agentic-commerce-blueprint`: passed (auto-setup + gateway health wait).
- API latency snapshot:
  - `/api/providers`: p95 ~21.79ms
  - `/api/providers/featured`: p95 ~14.32ms
- Cache invalidation:
  - `cacheVersion` changed immediately after install action (`18 -> 19`).

## Checks Passed
- `python backend/scripts/validate_providers.py`
- `python backend/scripts/provider_dry_run_lifecycle.py`
- `pytest backend/tests/test_provider_lifecycle.py`
- `npm run typecheck --prefix frontend`
- `npm run build --prefix frontend`

## Upstream Provider Repo Changes
- Not required in this run. Fixes were completed in Hub orchestration/wrapper layer and validated by real lifecycle requests.
