# Plan: Real Config And Benchmark Data For Four Providers

## Goal
- Make Machine fit, Last benchmark, and Quick config reflect real provider data for:
  - `agentic-commerce-blueprint`
  - `multi-agent-intelligent-warehouse`
  - `pdf-to-podcast`
  - `aiq`
- Remove misleading placeholder/fallback values where real runtime/config data exists.
- Keep Windows and Linux script behavior aligned for providers that support both platforms.

## Required Skills
- `plan-skill`: phase planning and checklist tracking.
- `backend-skill`: provider registry, runtime status, lifecycle and metrics collection.
- `frontend-skill`: provider detail rendering without changing the current design direction.
- `documentation-skill`: completion documentation.
- `logging-skill`: execution log.
- `push-code-skill`: final source push.

## Phase 1: Audit Current Data Path
- Estimate: 30-60 minutes.
- Trace backend provider registry, runtime status, metrics files, manifests, and frontend detail components.
- Identify every fallback value shown in Machine fit, Last benchmark, and Quick config.
- Compare each of the four real provider manifests and scripts.
- Acceptance: know exactly which value comes from manifest, runtime, metrics file, env file, or fallback.
- Status: completed.

## Phase 2: Provider-Specific Real Metadata
- Estimate: 45-90 minutes.
- Update manifest requirements/profile/port/install path values with defensible provider-specific data.
- Derive Quick config from actual runtime/default config where possible.
- Ensure `.env.local` keys required by real providers are passed without hardcoding secrets into source.
- Acceptance: Quick config and Machine fit are no longer generic for the four real providers.
- Status: completed.

## Phase 3: Real Metrics And Benchmark Collection
- Estimate: 60-150 minutes.
- Update provider `collect-metrics` scripts to read real process/container/endpoint state.
- Include clear status when not started, running, unhealthy, or missing dependencies.
- Avoid counting fallback messages as successful benchmark output.
- Keep Windows and Linux script outputs structurally consistent.
- Acceptance: Last benchmark changes based on real provider state and reports enough detail to debug failures.
- Status: completed.

## Phase 4: Frontend Data Display Validation
- Estimate: 30-75 minutes.
- Keep the current visual design but ensure the detail page consumes real status/config/metrics.
- Confirm media priority still uses provider `media/` assets first and fallback image only when none exist.
- Confirm page transition and theme switching optimizations still build after data changes.
- Acceptance: four provider detail pages show real values without new layout regressions.
- Status: completed.

## Phase 5: Four-Provider Real Lifecycle Validation
- Estimate: 120-300 minutes.
- For each real provider: delete deploy folder, install through Hub, run through Hub, verify health/logs/metrics/detail data, stop, and clean up.
- Fix and push upstream provider repos if source defects block clean clone/run.
- Rerun affected provider from a fresh clone until pass.
- Acceptance: all four providers pass install/run verification with no fallback-only result.
- Status: completed.

## Phase 6: Documentation, Logs, Final Push
- Estimate: 30-60 minutes.
- Document what real data is loaded and how to interpret metrics.
- Log the validation loop and final pass/fail evidence.
- Run final targeted tests/builds.
- Push the source repo.
- Acceptance: source is pushed, temporary test folders are cleaned, and plan statuses are complete.
- Status: completed.

## Completion Evidence - 2026-05-13
- `aiq`: real Hub install/run/health/metrics/stop/delete passed. Metrics reported `2 agents`.
- `agentic-commerce-blueprint`: real Hub install/run/health/metrics/stop/delete passed. Metrics reported `13 containers`, gateway `8088` healthy.
- `multi-agent-intelligent-warehouse`: real Hub install/run/health/metrics/stop/delete passed. Metrics reported `9 containers`, backend `8091` healthy.
- `pdf-to-podcast`: real Hub install/run/health/metrics/stop/delete passed. Metrics reported `9 containers`, API `8002` and frontend `7860` healthy.
- Final cleanup removed all four deploy folders and left `docker ps` empty.
- Final automated checks passed: backend pytest, backend ruff, frontend vitest, frontend typecheck, frontend build.
- AIQ frontend localhost follow-up passed after upstream commit `580610a`: deploy pulled `develop`, backend health returned 200, async agents returned 2 agents, `localhost:13080` returned 200, and metrics still reported `2 agents`.
- Quick config follow-up: provider config now writes local overrides to ignored `providers/{id}/runtime/config.local.json`, exposes env/key fields for the four real providers, injects saved env into lifecycle scripts, and makes port/install path editable instead of display-only.
