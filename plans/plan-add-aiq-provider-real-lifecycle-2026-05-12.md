# Plan: Add AIQ Provider With Real Lifecycle Validation

## Goal
- Add `aiq` from `https://github.com/PhuongHo03/aiq.git` as the fourth real provider.
- Validate the upstream provider with a real install/run cycle before Hub integration.
- If upstream has defects, fix and push the provider repo first, then delete and reclone to prove the fix.
- Add Hub manifest and Windows/Linux provider scripts.
- Validate Hub install/run/health/metrics/stop/delete by letting Hub clone the provider again from GitHub.
- No fallback-only pass, no dry run, no smoke-test-only acceptance.

## Required Skills
- `plan-skill`: phase planning and checklist tracking.
- `backend-skill`: provider runtime, lifecycle scripts, API behavior.
- `frontend-skill`: provider detail/card data surface if the new provider needs frontend exposure changes.
- `documentation-skill`: completion documentation.
- `logging-skill`: execution log.
- `push-code-skill`: final source push.

## Phase 1: Upstream Discovery And Clean Clone
- Estimate: 20-40 minutes.
- Clone `https://github.com/PhuongHo03/aiq.git` into an ignored working folder.
- Read README, dependency files, scripts, docker files, environment requirements, ports, and supported OS assumptions.
- Record the real startup command and health signal.
- Acceptance: upstream run path is understood from source files, not guessed.
- Status: completed.

## Phase 2: Upstream Real Test Loop
- Estimate: 45-120 minutes.
- Install dependencies using the provider's documented path.
- Run the provider with real environment variables from Hub `.env.local` when applicable.
- Hit a real health/API/UI endpoint and inspect runtime logs.
- If it fails, patch upstream source, commit, push to `PhuongHo03/aiq.git`, delete the local clone, reclone, and retest.
- Acceptance: a fresh clone of upstream can install and run successfully on this machine without Hub fallbacks.
- Status: completed.

## Phase 3: Hub Provider Integration
- Estimate: 45-90 minutes.
- Add `providers/aiq/aihub.provider.json`.
- Add Windows scripts: `setup.ps1`, `run.ps1`, `health.ps1`, `collect-metrics.ps1`, `stop.ps1`, `delete.ps1`.
- Add Linux scripts when the provider supports Linux: `setup.sh`, `run.sh`, `health.sh`, `collect-metrics.sh`, `stop.sh`, `delete.sh`.
- Add media placeholder folder support without requiring bundled images.
- Acceptance: Hub recognizes `aiq` as a real provider with install/run/stop/delete actions.
- Status: completed.

## Phase 4: Hub Real Install And Run Loop
- Estimate: 60-150 minutes.
- Delete any old `deploy/aiq`.
- Trigger Hub install so it clones from GitHub.
- Trigger Hub run, then verify status/health/logs/metrics against the real running provider.
- Stop and delete through Hub.
- If any issue appears, fix the Hub wrapper or upstream provider, push the needed repo, clear test folders, and rerun.
- Acceptance: Hub install/run works from a clean state and does not pass by fallback.
- Status: completed.

## Phase 5: Cleanup, Documentation, Push
- Estimate: 20-40 minutes.
- Remove ignored clone/test/deploy leftovers created during validation.
- Write completion documentation and execution log.
- Run targeted backend/frontend tests and build checks.
- Push the source repository after review.
- Acceptance: working tree only contains intended source/docs/log changes plus user-owned untracked media if still present.
- Status: completed.

## Completion Evidence - 2026-05-13
- AIQ clean Hub install cloned `https://github.com/PhuongHo03/aiq.git` into `deploy/aiq`.
- AIQ Hub run started the real backend on `18080` and UI on `13080`.
- Real checks passed: `/health` 200, `/v1/jobs/async/agents` 200 with 2 agents, frontend HTML 200, metrics benchmark `2 agents`.
- Hub stop/delete completed and `deploy/aiq` was removed.
- Backend runner was fixed to avoid stdout pipe hangs from provider child processes.
- Runtime JSON loading now accepts PowerShell UTF-8 BOM output.
- Follow-up cold-start timeout fix pushed to upstream `PhuongHo03/aiq.git` `develop` commit `8973979`.
- Clean Hub retest after upstream push passed: run completed in 326 seconds and metrics reported `2 agents`.
- Follow-up frontend bind fix pushed to upstream `PhuongHo03/aiq.git` `develop` commit `580610a`.
- AIQ was restarted from the updated GitHub clone; gateway now listens on `0.0.0.0:13080` instead of the Windows/Git Bash hostname IP, and `http://localhost:13080` returns 200 with title `AI-Q`.
