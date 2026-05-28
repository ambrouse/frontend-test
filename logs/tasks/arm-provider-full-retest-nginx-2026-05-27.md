# ARM Provider Full Retest and Nginx Compose - 2026-05-27

## 17:21 Start

- User requested a full provider retest plan for the current ARM/aarch64 machine because provider installs are producing many small failures.
- User also requested screenshot proof for each provider function and an Nginx server managed by Docker Compose.
- Applied skills: `plan-skill`, `logging-skill`, `testing-skill`, `backend-skill`, `frontend-skill`, `security-skill`.

## Initial Baseline

- Machine architecture: `aarch64`.
- Existing Hub tmux session had frontend on `0.0.0.0:3000` and backend on `0.0.0.0:8000`.
- Current provider registry had 8 ready providers.
- Created plan: `plans/plan-arm-provider-full-retest-nginx.md`.

## Current Status

- Nginx Docker Compose setup is added and running.
- Provider-by-provider ARM retest evidence has not started yet.

## Nginx Compose Result

- Added `docker-compose.nginx.yml`.
- Added `infra/nginx/templates/aihub.conf.template`.
- Started container `ai-hub-nginx` with Docker Compose.
- Verified:
  - `docker compose -f docker-compose.nginx.yml config` passed.
  - Container health is `healthy`.
  - `http://127.0.0.1/nginx-health` returned `ok`.
  - `http://127.0.0.1/api/health` returned `{"ok":true}`.
  - `http://192.168.2.182/api/health` returned `{"ok":true}`.
  - `http://192.168.2.182/` returned HTTP `200` through Nginx.

## Evidence Structure

- Created root evidence report: `tests/arm-provider-full-retest-evidence-2026-05-27/README.md`.
- Created pending provider reports for all 8 providers.
- Evidence folders are intentionally pending until real ARM lifecycle/function screenshots are captured and reviewed.

## Agentic Commerce - ARM Retest Start

- Started Phase 4 for `agentic-commerce-blueprint`.
- Baseline status already showed failed install with: `scripts/linux/setup.sh: line 15: python: command not found`.
- Confirmed this ARM machine has `/usr/bin/python3` but no `python` command.
- Root cause is the Hub Linux wrapper using `python` directly; this is a Hub wrapper fix, not a provider source repo fix.

## Agentic Commerce - Fixes Applied

- Hub wrapper fix:
  - Updated Agentic Commerce Linux `setup.sh`, `run.sh`, and `stop.sh` to use `python3` with `python` fallback.
  - `bash -n` passed for the edited scripts.
- Fresh install after wrapper fix:
  - Hub delete completed.
  - Hub install completed from GitHub clone.
  - Fresh clone commit before provider source fix: `fc60c26`.
- First ARM run failed because provider source compose used fixed global container names:
  - Error: container name `/nginx` already existed from another local stack.
- Provider source fix:
  - Removed fixed `container_name` values from `docker-compose.yml`, `docker-compose.infra.yml`, and `docker-compose-nim.yml` in the provider source clone.
  - `docker compose -f docker-compose.infra.yml -f docker-compose.yml config` passed.
  - Committed and pushed provider repo commit `1932279 fix: namespace compose containers on ARM 2026-05-27`.

## Agentic Commerce - Retest Result

- Cleared old source/deploy through Hub delete.
- Fresh Hub install cloned pushed provider commit `1932279`.
- Fresh clone no longer contains fixed `container_name` entries.
- Hub run completed in 250 seconds.
- Gateway health returned HTTP 200 at `http://127.0.0.1:8088/api/health`.
- Hub metrics reported gateway healthy with 10-11 running containers during sampling.
- Captured evidence:
  - lifecycle: Hub running status and progress logs.
  - logs: Hub service logs panel.
  - app: provider app loaded product catalog.
  - function: native product checkout session for Graphic Tee.
  - blocker: Apps SDK search for `graphic tee` fails because `NVIDIA_API_KEY` is missing.
- Cleanup:
  - Hub stop completed.
  - Hub delete completed.
  - No remaining `agentic-commerce-blueprint` containers.
  - `deploy/agentic-commerce-blueprint` removed.

## AIVA - ARM Retest Start

- Started Phase 5 for `ai-virtual-assistant-provider`.

## AIVA - Retest Result

- Hub delete completed before install.
- Hub install completed from fresh GitHub clone.
- Fresh clone commit: `47db4d6`.
- Hub run failed fast with `Error: NVIDIA_API_KEY is missing in .env`.
- This is a missing required secret for hosted API mode, not a provider source code fix.
- Captured blocker screenshot: `tests/arm-provider-full-retest-evidence-2026-05-27/ai-virtual-assistant-provider/blockers/01-run-missing-nvidia-api-key.png`.
- Hub delete cleanup completed and `deploy/aiva` was removed.

## AIQ - ARM Retest Start

- Started Phase 6 for `aiq`.

## AIQ - Retest Result

- Fixed Hub AIQ Linux wrapper to use `python3` with `python` fallback.
- Fixed AIQ and Web Agent provider manifests to check `python3 --version` on Linux hosts where `python` is absent.
- Hub delete completed before install.
- Hub install completed from fresh GitHub clone.
- Fresh clone commit: `2ddbbde`.
- Hub run failed fast with `[setup] Missing NVIDIA_API_KEY in deploy/.env`.
- This is a missing required secret for hosted knowledge mode, not a provider source code fix.
- Captured blocker screenshot: `tests/arm-provider-full-retest-evidence-2026-05-27/aiq/blockers/01-run-missing-nvidia-api-key.png`.
- Hub delete cleanup completed and `deploy/aiq` was removed.

## Warehouse - ARM Retest Start

- Started Phase 7 for `multi-agent-intelligent-warehouse`.

## Warehouse - Retest Result

- Fixed Hub Warehouse Linux wrapper scripts to use `python3` with `python` fallback.
- `bash -n` passed for the edited Warehouse wrapper scripts.
- Hub delete completed before install.
- Hub install completed from fresh GitHub clone.
- Fresh clone commit: `d5e0c14`.
- Hub run completed in 46 seconds.
- Provider smoke checks passed:
  - Backend health OK.
  - Frontend OK.
  - Provider Nginx gateway OK.
  - Default users seeded.
  - Auth/chat smoke checks completed by provider script.
- Runtime endpoints from provider output:
  - Frontend direct: `http://localhost:6009`.
  - Provider Nginx gateway: `http://localhost:6010`.
  - Backend API: `http://localhost:6008`.
- Browser evidence captured and reviewed:
  - Hub running status.
  - Hub service logs and detailed logs streaming.
  - Provider login page.
  - Login/dashboard with seeded warehouse data.
  - Equipment and assets list.
- Remaining blocker:
  - Chat AI request returns `Unable to connect to LLM service`; captured blocker screenshot.
  - This is runtime service/key/network configuration, not an ARM install failure.
- Cleanup initially failed because provider Docker data under `deploy/compose/data/postgres` was root-owned.
- Fixed Warehouse Hub wrapper cleanup to chown root-owned deploy data with passwordless `sudo` fallback before `rm -rf`.
- Retested Hub delete; cleanup completed and `deploy/multi-agent-intelligent-warehouse` was removed.

## Nemotron Voice Agent - ARM Retest Start

- Started Phase 8 for `nemotron-voice-agent-provider`.

## Nemotron Voice Agent - Retest Result

- Hardened shared Linux provider dispatcher before run:
  - Added safe deploy removal with passwordless `sudo chown` fallback for root-owned Docker bind data.
  - Fixed `wait_http` local variable initialization under `set -u`.
- Hub delete completed before install.
- Hub install completed from fresh GitHub clone.
- Fresh clone commit: `3a01ebc`.
- First run exposed the `wait_http` bug, leaving containers up; stopped the stack through Hub and reran after patch.
- Second Hub run completed in 9 seconds.
- Runtime checks:
  - UI app healthy on `http://localhost:9000`.
  - Pipeline docs reachable on `http://localhost:7860/docs`.
  - Docker reports `nemotron-voice-agent-ui-app-1` and `nemotron-voice-agent-python-app-1` healthy.
- Browser evidence captured and reviewed:
  - Hub running status.
  - Hub service logs and detailed logs.
  - Provider UI ready.
  - Start action result.
  - Configure blocker screenshot.
- Remaining blocker:
  - Full voice conversation is not proven; UI shows `No voices available` after Start and `Requested device not found` on Configure.
  - Host has no `NVIDIA_API_KEY` or `NGC_API_KEY`.
- Cleanup:
  - Hub stop completed.
  - Hub delete completed.
  - No remaining Nemotron containers.
  - `deploy/nemotron-voice-agent-provider` removed.

## PDF to Podcast - ARM Retest Start

- Started Phase 9 for `pdf-to-podcast`.

## PDF to Podcast - Fix and Retest Result

- Fixed Hub PDF to Podcast Linux wrapper scripts to use `python3` with `python` fallback.
- Added safe cleanup in the wrapper for root-owned Docker bind data.
- `bash -n` passed for edited wrapper scripts.
- Hub delete completed before install.
- Hub install completed from fresh GitHub clone.
- Fresh clone before provider source fix: `c27f331`.
- First run failed in provider source with `No free port found between 6116 and 6050`.
- Provider source fix:
  - Updated `deploy/pdf-to-podcast/setup.sh` so AI Hub port scan defaults to `6200` and expands if the inherited start port is above the ceiling.
  - `bash -n deploy/pdf-to-podcast/setup.sh` passed.
  - Rerun on edited clone passed.
  - Committed and pushed provider repo commit `bbea1b0 fix: widen AI Hub port allocation on Linux 2026-05-27`.
- Fresh verification after push:
  - Hub stop completed.
  - Hub delete completed and `deploy/pdf-to-podcast` was removed.
  - Hub install cloned fresh commit `bbea1b0`.
  - Hub run completed in 65 seconds.
  - Runtime endpoints: frontend `http://localhost:7860`, API health `http://localhost:8002/health`.
- Browser evidence captured and reviewed:
  - Hub running status.
  - Hub service logs and detailed logs.
  - Provider UI ready.
  - Sample PDF upload.
  - PDF processing reached `All PDFs processed successfully`.
- Remaining blocker:
  - Full podcast generation failed at agent stage with `Failed to get response after 5 attempts`.
  - Host has no hosted NVIDIA/ElevenLabs credentials, so full audio generation is not counted as pass.
- Cleanup:
  - Hub stop completed.
  - Hub delete completed.
  - No remaining `pdf-to-podcast-*` containers.
  - `deploy/pdf-to-podcast` removed.

## Shop Retail - ARM Retest Start

- Started Phase 10 for `shop-retail-provider`.

## Shop Retail - Retest Result

- Hub delete completed before install.
- Hub install completed from fresh GitHub clone.
- Fresh clone commit: `f2cec9c`.
- Hub run completed in 60 seconds.
- Runtime:
  - Provider Nginx on `http://localhost:13000`.
  - Chain server, catalog retriever, memory retriever, rails, Milvus, MinIO and etcd containers started under namespaced Compose project.
- Browser evidence captured and reviewed:
  - Hub running status.
  - Hub service logs and detailed logs.
  - Provider UI ready.
  - Retail assistant chat accepts prompt and responds.
- Remaining limitation:
  - Product-card search result was not proven; response falls back to scripted assistant guidance.
  - Host has no NVIDIA key for full grounded retail generation.
- Cleanup:
  - Hub stop completed.
  - Hub delete completed.
  - No remaining `aihub-shop-retail-provider-*` containers.
  - `deploy/shop-retail-provider` removed.

## Web Agent - ARM Retest Start

- Started Phase 11 for `web-agent`.

## Web Agent - Retest Result

- Fixed Web Agent Hub Linux wrapper:
  - `python3` with `python` fallback for env edits.
  - Safe deploy cleanup for root-owned Docker data.
  - Run source script through `bash` because fresh clone `run.sh` is not executable.
- `bash -n` passed for edited wrapper scripts.
- Hub delete completed before install.
- Hub install completed from fresh GitHub clone.
- Fresh clone commit: `fc38862`.
- Hub run first failed with `Permission denied` on `deploy/web-agent/run.sh`; after wrapper fix, rerun completed in 6 seconds.
- Runtime:
  - Frontend: `http://localhost:3005`.
  - Backend health: `http://localhost:8011/api/v1/health`.
  - Backend reports `llm_enabled: true` with local base URL `http://127.0.0.1:6106/v1`.
  - Provider-scoped SearXNG container started.
- Browser evidence captured and reviewed:
  - Hub running status.
  - Hub service logs and detailed logs.
  - Provider UI ready.
  - Search form blocker screenshot.
- Remaining blocker:
  - Search-backed answer is not proven.
  - UI search form accepts text but did not submit during browser validation.
  - Direct backend search request succeeded but returned zero Tavily/SearXNG results for the sampled query.
- Cleanup:
  - Hub stop completed.
  - Hub delete completed.
  - Provider-scoped `web-agent-searxng` container removed.
  - `deploy/web-agent` removed.

## Final Verification

- Restarted Hub frontend in tmux session `ai-hub`, window `frontend`, using:
  - `AIHUB_ALLOWED_DEV_ORIGINS=192.168.2.182`
  - `NEXT_PUBLIC_API_BASE=http://192.168.2.182`
  - `npm run dev --prefix frontend -- --hostname 0.0.0.0`
- tmux session now has windows `backend` and `frontend`.
- Nginx verification:
  - `docker compose -f docker-compose.nginx.yml config` passed.
  - `ai-hub-nginx` is healthy.
  - `http://127.0.0.1/nginx-health` returned `ok`.
  - `http://127.0.0.1/api/health` returned `{"ok":true}`.
  - `http://192.168.2.182/api/health` returned `{"ok":true}`.
- Provider manifest validation:
  - `./.venv/bin/python backend/scripts/validate_providers.py` passed.
  - Result: `Validated 8 provider manifests`.
- Frontend validation:
  - `npm run typecheck --prefix frontend` passed.
- Evidence hygiene:
  - No non-`.png`/`.md` files remain in evidence folder.
  - Duplicate image hash scan is clean.
  - Secret pattern scan across evidence, task log and plan is clean.

## Final Provider Stability Summary

- Most stable without hosted keys on this ARM host:
  - `multi-agent-intelligent-warehouse`: local stack/login/dashboard/equipment pass; AI chat needs LLM service/key configuration.
  - `shop-retail-provider`: install/run/UI pass; full grounded product search needs NVIDIA key.
  - `pdf-to-podcast`: install/run/upload/PDF processing pass after pushed source fix; full podcast generation needs hosted LLM/TTS keys.
  - `nemotron-voice-agent-provider`: UI/pipeline pass; full voice conversation needs device/voice/key availability.
- Blocked by missing required NVIDIA key at run:
  - `ai-virtual-assistant-provider`
  - `aiq`
- Partial with source fix:
  - `agentic-commerce-blueprint`: source fix pushed at `1932279`; native checkout pass; Apps SDK search needs NVIDIA key.
  - `pdf-to-podcast`: source fix pushed at `bbea1b0`; fresh install/run verified.
- Needs follow-up source/UI investigation:
  - `web-agent`: install/run/frontend/backend pass after wrapper fixes; search-backed answer blocked by UI non-submit and zero backend results.
