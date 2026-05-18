# Real Provider Config And AIQ Lifecycle - 2026-05-13

## Summary
- Fixed provider lifecycle execution so Hub tasks no longer hang when provider child processes keep stdout handles open.
- Added UTF-8 BOM tolerant JSON reads for runtime status and metrics written by Windows PowerShell scripts.
- Added real metrics collection for `agentic-commerce-blueprint`, `multi-agent-intelligent-warehouse`, `pdf-to-podcast`, and `aiq`.
- Added `aiq` default config and validated the provider from a clean Hub clone.
- Updated the provider detail benchmark card to prefer live metrics VRAM/benchmark values.

## Real Lifecycle Evidence
- `aiq`: clean Hub install cloned `PhuongHo03/aiq.git`, Hub run started backend `18080` and frontend `13080`, `/health` returned 200, `/v1/jobs/async/agents` returned 2 agents, metrics reported `2 agents`, stop/delete cleaned deploy.
- `agentic-commerce-blueprint`: Hub install/run passed, gateway `8088` was healthy, metrics reported `13 containers`, stop/delete cleaned deploy.
- `multi-agent-intelligent-warehouse`: Hub install/run passed, backend health `8091` passed, metrics reported `9 containers`, stop/delete cleaned deploy.
- `pdf-to-podcast`: Hub install/run passed, API `8002` and frontend `7860` passed, metrics reported `9 containers`, stop/delete cleaned deploy.

## Final Checks
- Backend pytest: 15 passed.
- Backend ruff: passed.
- Frontend vitest: 7 passed.
- Frontend typecheck: passed after build regenerated `.next/types`.
- Frontend production build: passed.
- Secret scan: passed.
- Provider manifest validation: 34 provider manifests passed.
- Cleanup: all four tested deploy folders removed, `docker ps` empty, and no provider process remained under `deploy`.

## Follow-Up Fix - 2026-05-13
- AIQ cold start later exceeded the original provider `setup.sh` 60 second service readiness window even though backend completed startup shortly after.
- Upstream provider fix was pushed to `PhuongHo03/aiq.git` branch `develop` at commit `8973979` (`Extend service readiness timeout for Windows lifecycle`).
- Hub wrapper also keeps a post-clone timeout patch so clean clones are protected if an older provider revision is used.
- Retest from a clean GitHub clone passed: Hub install completed, Hub run completed in 326 seconds, status was `running`, backend PID was captured, and metrics reported `2 agents`.
- Cleanup after retest removed `deploy/aiq` and left no listeners on `18080`, `13080`, or `13081`.

## Frontend Bind Follow-Up - 2026-05-13
- AIQ frontend initially started but bound the gateway to the Git Bash/Windows hostname address (`192.168.2.22:13080`), so Chrome requests to `localhost:13080` were refused.
- Upstream provider fix was pushed to `PhuongHo03/aiq.git` branch `develop` at commit `580610a` (`Bind UI gateway to wildcard frontend host`).
- The provider now uses `AIQ_FRONTEND_HOST`/`HOST` before falling back to `0.0.0.0`, and `setup.sh` exports `AIQ_FRONTEND_HOST=0.0.0.0` by default.
- Hub wrapper setup scripts also patch older clones so `server.js` does not bind from `HOSTNAME`.
- Retest after pulling `580610a` passed: `0.0.0.0:13080` is listening, `http://localhost:13080` returned 200 with title `AI-Q`, backend `/health` returned 200, `/v1/jobs/async/agents` returned 2 agents, and metrics reported `2 agents`.

## Quick Config Follow-Up - 2026-05-13
- Quick config is now an editable local provider config instead of read-only metadata.
- Saved values are stored in ignored `providers/{id}/runtime/config.local.json`, so API keys are not written to tracked provider manifests.
- Backend lifecycle execution injects saved `env` values plus editable `port`, `branch`, and `installDirectory` into provider scripts.
- The four real providers now expose their needed env fields: NVIDIA/NGC and service keys for `agentic-commerce-blueprint`, NVIDIA/Tavily/Serper and AIQ ports for `aiq`, NVIDIA embedding/rail and compose ports for `multi-agent-intelligent-warehouse`, and NVIDIA/ElevenLabs/API ports for `pdf-to-podcast`.
- Validation passed: backend pytest 16 passed, backend ruff passed, frontend vitest 8 passed, frontend typecheck passed, provider manifest validation passed, and a dry-run config smoke test confirmed custom install path/env reaches lifecycle setup.

## Hub Hydration Follow-Up - 2026-05-13
- Fixed a Hub hydration mismatch where `HubExplorer` read `sessionStorage` during initial render.
- The server rendered the empty carousel while the browser rendered cached provider data, producing a `hub-carousel-empty` versus `hub-carousel` class mismatch.
- Cached Hub and selected-provider data now load after hydration in `useEffect`, so the first server/client render is deterministic.
- Validation passed: frontend vitest 8 passed, frontend typecheck passed, and `next build` passed.

## Provider Key Flow Follow-Up - 2026-05-13
- Removed the legacy action-level `nvidiaApiKey` request field.
- Provider lifecycle scripts for the four real providers no longer read `.env.local` as a hidden key fallback.
- Setup/run now receive keys only through Quick config values injected by the backend into the lifecycle environment.
- Validation passed: backend pytest 16 passed, backend ruff passed, provider manifests passed, frontend vitest 8 passed, and frontend typecheck passed.
