# Provider NVIDIA Full Stability Retest - 2026-05-27

## 23:45 Start

- User requested a full provider retest/fix loop for every provider on this Hub infrastructure.
- Required skills: `plan-skill`, `testing-skill`; also using `logging-skill`, `frontend-skill`, `backend-skill`, `security-skill`, and `push-code-skill` because the task touches UI, backend runtime, secrets, and provider repo pushes.
- Important security note: local NVIDIA credentials are used only from ignored local env files/process environment and must not be written into evidence, logs, docs, or commits.

## Baseline

- Active Hub providers detected:
  - `agentic-commerce-blueprint`
  - `ai-virtual-assistant-provider`
  - `aiq`
  - `multi-agent-intelligent-warehouse`
  - `nemotron-voice-agent-provider`
  - `pdf-to-podcast`
  - `shop-retail-provider`
  - `web-agent`
- Existing worktree is dirty before this pass; unrelated changes will not be reverted.
- Existing tmux session `ai-hub` has backend and frontend windows, which will be reused/restarted so long-running tasks survive SSH disconnects.
- `.env.local` was prepared locally with redacted `NVIDIA_API_KEY` and `NGC_API_KEY` values derived from the user-provided local key source.

## Plan

- Created `plans/plan-provider-nvidia-full-stability-retest.md`.
- Evidence target: `tests/provider-nvidia-full-stability-evidence-2026-05-27/`.
- Provider pass requires real Hub install/run evidence plus provider UI/function output. Missing third-party keys or device-only workflows must be documented only after practical fixes/workarounds are exhausted.

## Hub Runtime

- Ran `npm install --prefix frontend`; dependencies were already up to date. `npm audit` reports 1 moderate severity issue, not fixed automatically during this pass.
- Recreated the `ai-hub` tmux backend window and started uvicorn with `.env.local` sourced so provider lifecycle scripts inherit `NVIDIA_API_KEY`/`NGC_API_KEY`.
- Verified:
  - `GET /api/health` returned ok.
  - `GET /api/providers/summary` returned 8 total, 8 ready, 0 blocked, 0 installed, 0 running.

## Core Gate

- `backend/scripts/validate_providers.py`: passed for 8 provider manifests.
- `backend/scripts/provider_dry_run_lifecycle.py`: passed for 6 providers covered by the current dry-run script.
- Bash syntax check for `setup.sh` and all Linux provider scripts: passed.
- `npm run typecheck --prefix frontend`: passed.
- `npm run test --prefix frontend`: passed, 3 files / 9 tests.

## Backend Reload Issue

- First `agentic-commerce-blueprint` install cloned source into `deploy/agentic-commerce-blueprint` at provider commit `1932279`.
- Because uvicorn was running with `--reload`, file creation under `deploy/` triggered backend reload and erased the in-memory task store during polling.
- Switched backend tmux command to no-reload uvicorn for provider validation:
  - `python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --app-dir backend`
- Reverified Hub health after restart. Provider summary showed 8 ready, 1 installed, 0 running.

## Hub Env Fix

- Agentic run showed provider services restarting with missing NVIDIA key guidance.
- Confirmed deployed `.env` had `NVIDIA_API_KEY` and `NGC_API_KEY` length 0 even though backend process had local env.
- Root cause: backend `_apply_config_env` applied empty manifest/default env values over non-empty process env.
- Fixed `backend/app/services/provider_runtime.py` so empty provider config env does not clear an existing process env value.
- Added regression test `test_empty_provider_env_does_not_clear_process_secret`.
- Verification:
  - `pytest backend/tests/test_provider_lifecycle.py -q`: 8 passed.
  - `ruff check backend/app/services/provider_runtime.py backend/tests/test_provider_lifecycle.py`: passed.

## Agentic Commerce Result

- Hub delete initially reported completed while containers remained.
- Hardened `providers/agentic-commerce-blueprint/scripts/linux/delete.sh` with compose project label fallback cleanup for containers, networks and volumes.
- `bash -n providers/agentic-commerce-blueprint/scripts/linux/delete.sh`: passed.
- Retested delete; no `agentic-commerce-blueprint` compose containers remained.
- Fresh Hub install cloned provider commit `1932279`.
- Redacted deploy env check showed `NVIDIA_API_KEY` and `NGC_API_KEY` populated.
- Fresh Hub run completed:
  - State: running.
  - Gateway: `8088` healthy.
  - Metrics: 13 running containers.
- Captured and reviewed evidence:
  - Hub lifecycle running screenshot.
  - Hub full-page progress/log screenshot.
  - Provider app ready screenshot.
  - Provider native checkout session screenshot showing created checkout, ready-for-payment update, total due and promotion-agent output.

## AI Virtual Assistant Result

- Initial AIVA runs exposed several infrastructure/provider issues:
  - amd64-only images crashed on this ARM host until binfmt support was installed.
  - The provider UI defaulted to browser-blocked port `6000`.
  - The provider inherited unrelated Hub host Postgres env values, so app services pointed at the wrong database/user.
  - Old compose project/volume state could survive cleanup.
- Installed amd64 binfmt with Docker and verified the host registered `qemu-x86_64`.
- Updated and pushed provider source fixes:
  - `dae6539` changed the runtime default UI port to `6020`.
  - `2b42591` changed `.env.example` UI port to `6020`.
  - `6d55b2b` added isolated Postgres env defaults.
- Updated Hub shared AIVA wrapper behavior:
  - Writes `COMPOSE_PROJECT_NAME=aihub-aiva`.
  - Writes default Postgres app/read-only user and database values.
  - Deletes compose resources with the runtime override and label fallback cleanup.
- Fresh Hub install after the provider push cloned source commit `6d55b2b`.
- Redacted deploy env check showed NVIDIA credentials present and AIVA-specific Postgres/UI settings applied.
- Fresh Hub run completed:
  - State: running.
  - Health: ok.
  - Provider UI: `http://127.0.0.1:6020`.
  - Backend health checks on agent/API services returned 200.
- Captured and reviewed evidence:
  - Hub lifecycle running screenshot.
  - Hub full-page progress/log screenshot showing startup complete and UI `6020`.
  - Provider app ready screenshot.
  - Provider delivery question screenshot showing the user question and answer: Shield TV Pro delivered, with purchase history visible in the same frame.

## AI-Q Result

- Initial AI-Q Hub run started, but the provider UI could not enable file upload when opened through the frontend because:
  - The provider frontend inherited unrelated host `BACKEND_URL`, so `/api/v1/data_sources` proxied to the wrong backend path.
  - After forcing the correct backend URL, the backend had been resolved to port `6000`, which Node/undici treats as an unsafe port and rejects with `bad port`.
  - `delete.sh` called `stop.sh` directly even though the script was not executable, so cleanup failed until the stale process was killed and wrapper fixed.
- Updated Hub AI-Q wrapper scripts:
  - Sanitize backend port to `6042` when Hub config supplies a port outside AI-Q's local range.
  - Set `AIQ_PORT_MIN=6001` so provider port resolution does not fall back to unsafe `6000`.
  - Force frontend `BACKEND_URL` and `NEXT_PUBLIC_BACKEND_URL` to the resolved backend URL.
  - Invoke `stop.sh` and deployed `setup.sh` via `bash`.
- Fresh Hub delete -> install -> run after these fixes completed:
  - State: running.
  - Frontend: `6001`.
  - Backend: `6042`.
  - Frontend `/api/v1/data_sources` returned web search, knowledge layer and paper search.
- Function validation:
  - Opened the provider UI at `http://localhost:6001`, the URL advertised by the provider runtime. `127.0.0.1` leaves Next dev hydration incomplete due dev-origin protection.
  - Uploaded `aiq-explanation.md`; ingestion completed and NVIDIA embeddings returned 200.
  - Asked for the three technical structure entries from the uploaded document.
  - Final answer cited `aiq-explanation.md` and listed workflow/agent core, web API backend and frontend UI entries.
- Captured and reviewed evidence:
  - Hub lifecycle running screenshot.
  - Hub full-page progress/log screenshot.
  - Provider app ready screenshot with hydrated UI and data-source counts.
  - File upload available screenshot.
  - Grounded chat answer screenshot with document reference.
- Remaining limitation: Tavily and Serper keys are not present, so web and paper search tools are not marked as pass in this run; AI-Q's built-in Knowledge Layer path is pass.

## Multi-Agent Intelligent Warehouse Result

- Initial MAIW Hub configuration used browser-unsafe/conflicting default ports.
- Updated Hub wrapper and config defaults:
  - Frontend/UI default `6009`.
  - Backend default `6008`.
  - Nginx default `6010`.
  - Run and metrics scripts sanitize/export the same resolved frontend/backend ports.
- Fresh Hub delete -> install -> run after these fixes completed:
  - State: running.
  - Frontend: `6009`.
  - Backend health: healthy database, Redis and Milvus services.
  - Provider login accepted the documented demo admin credentials.
- Function validation:
  - Dashboard loaded after login and showed online system status, 12 equipment assets and 2 maintenance-needed assets.
  - Chat assistant answered a maintenance query with FL-03 and HUM-01 and rendered structured equipment data.
- Captured and reviewed evidence:
  - Hub lifecycle running screenshot.
  - Hub full-page progress/log screenshot.
  - Provider login screen screenshot.
  - Authenticated dashboard screenshot.
  - Maintenance chat answer screenshot with prompt and output in the same frame.

## Nemotron Voice Agent Result

- Fresh Hub delete -> install -> run completed:
  - Provider source cloned from `mionm/nemotron-voice-agent-provider.git` at `3a01ebc`.
  - State: running.
  - UI: `9000`.
  - Pipecat/FastAPI docs: `7860`.
  - Docker services: `nemotron-voice-agent-python-app-1` and `nemotron-voice-agent-ui-app-1` healthy.
- Function validation:
  - Opened provider UI from the Hub-run service.
  - Started WebRTC using headless Chromium fake microphone permission.
  - Browser console showed ICE connection connected and data channel opened.
  - Provider UI rendered the bot introduction: "I'm Nemotron Nano, a model developed by NVIDIA."
  - Runtime logs showed the pipeline linking ASR -> LLM -> TTS, NVIDIA LLM token usage and hosted TTS generation for the intro response.
- Captured and reviewed evidence:
  - Hub lifecycle running screenshot.
  - Hub full-page progress/log screenshot.
  - Provider app ready screenshot.
  - WebRTC session screenshot showing bot output and populated language/voice selectors.
- Limitation:
  - A full spoken ASR user turn was not attempted because this SSH/headless host has no local speech-file generator available for Chromium fake microphone input. The session still initialized the ASR processor and proved the WebRTC, LLM and TTS path without fallback UI.

## PDF to Podcast Result

- Initial fresh Hub run started successfully, but frontend-generated jobs failed at TTS:
  - The Gradio frontend did not receive the Edge fallback voice env values.
  - The frontend therefore submitted stale ElevenLabs voice IDs while the runtime TTS provider was `edge`.
  - TTS fallback mapping was computed but not passed into `_process_dialogue`.
- Updated and pushed provider source fix:
  - Commit `4d0dfdc` in `PhuongHo03/pdf-to-podcast.git`.
  - Added `DEFAULT_VOICE_1`, `DEFAULT_VOICE_2`, Edge voice envs and `TTS_PROVIDER` to the frontend service environment.
  - Passed the validated fallback `voice_mapping` into TTS dialogue processing.
- Verification before reinstall:
  - `python3 -m py_compile deploy/pdf-to-podcast/services/TTSService/main.py`: passed.
  - Manual API job with `sample.pdf` and Edge voice generated a completed MP3.
- Fresh Hub delete -> install -> run after source push completed:
  - Provider source cloned at `4d0dfdc`.
  - State: running.
  - Frontend: `7861`.
  - API: `8003`.
  - Health: Redis, PDF, agent and TTS services up.
- Function validation:
  - Opened the Hub-run Gradio frontend.
  - Uploaded `services/PDFService/sample.pdf`.
  - Enabled monologue mode and generated a podcast from the UI.
  - UI progress showed PDF processing, agent outline/transcript generation and TTS processing.
  - UI output exposed MP3 audio, transcript JSON and generation-history JSON.
- Captured and reviewed evidence:
  - Hub lifecycle running screenshot.
  - Hub full-page progress/log screenshot.
  - Provider Gradio UI ready screenshot.
  - Frontend generation progress screenshot.
  - Frontend generation completed screenshot with MP3/transcript/history files.

## Shop Retail Provider Result

- Initial fresh Hub run started, but chat requests failed with NVIDIA `401 Unauthorized` because Docker Compose interpolation received empty shell env placeholders for `LLM_API_KEY`/`EMBED_API_KEY` instead of the populated deploy `.env` values.
- Updated Hub shared wrapper:
  - For `shop-retail-provider`, source the hydrated deploy `.env` before `docker compose up`.
  - `bash -n providers/_shared/linux-provider-dispatch.sh`: passed.
- Fresh Hub delete -> install -> run after the wrapper fix completed:
  - Provider source cloned from `mionm/Shop-Retail-Provider-mion-.git` at `f2cec9c`.
  - State: running.
  - UI/nginx: `13000`.
  - Chain server health: ok.
  - Catalog text embeddings returned NVIDIA 200 responses.
- Function validation:
  - Opened the Hub-run retail UI.
  - Asked: "Do you have any summer skirts?"
  - Assistant returned multiple skirt products with descriptions and prices, and product cards were visible.
- Captured and reviewed evidence:
  - Hub lifecycle running screenshot.
  - Hub full-page progress/log screenshot.
  - Provider UI ready screenshot.
  - Text retail search output screenshot.
- Blocker:
  - Image embedding/search is blocked by NVIDIA `nvclip` hosted endpoint returning `400 Bad Request` with `DEGRADED function cannot be invoked`.
  - The same credential works for LLM and text embeddings, so this is recorded as an external hosted endpoint blocker rather than a missing key.

## Web Agent Result

- Initial Web Agent fresh Hub run exposed two source/provider runtime issues:
  - Stale `uvicorn`/Next.js processes could remain alive after deploy deletion, so a new Hub health check could attach to an old process whose working directory had been deleted.
  - The frontend rewrites proxied `/api/v1/*` to the wrong backend because `API_PROXY_PORT`/`API_PROXY_TARGET` were not exported into `next dev`.
- Updated and pushed provider source fixes:
  - Commit `09bd0c7` in `baolnq-ai/web-agent.git`: clear stale local dev listeners before starting.
  - Commit `3b55b48` in `baolnq-ai/web-agent.git`: export API proxy env for Next.js dev.
- Updated Hub wrapper defaults:
  - SearXNG default port is `6004`.
  - Wrapper clears stale listeners before run and deletes by port during delete.
- Fresh Hub delete -> install -> run after source pushes completed:
  - Provider source cloned at `3b55b48`.
  - State: running.
  - Frontend: `3005`.
  - Backend: `8011`.
  - SearXNG: `6004`.
  - Frontend proxy `/api/v1/chat/sessions` returned 200 through `localhost:3005`.
- Function validation:
  - Opened the Hub-run Web Agent UI at `http://localhost:3005`.
  - Created a new chat session from the frontend.
  - Asked: "What is OpenAI? Answer briefly and cite sources."
  - The UI called `/api/v1/search/stream`, returned provider `searxng_fallback`, confidence 90%, a generated answer, and 5 visible sources.
- Captured and reviewed evidence:
  - Hub lifecycle running screenshot.
  - Hub full-page progress/log screenshot.
  - Provider UI ready screenshot.
  - Frontend web-search answer screenshot with sources.
- Limitation:
  - Tavily-specific search was not marked as pass because no Tavily key is configured. The provider-supported SearXNG fallback path passed through the frontend with real web sources.

## Final Hygiene

- `PYTHONPATH=backend ./.venv/bin/python backend/scripts/validate_providers.py`: passed, 8 provider manifests validated.
- `bash -n` passed for modified Linux provider scripts and shared dispatcher.
- `./.venv/bin/python -m pytest backend/tests/test_provider_lifecycle.py -q`: passed, 8 tests.
- Secret scan across the final evidence folder, task log and plan: 0 hits.
- Evidence completeness scan:
  - 8 provider README files present.
  - Every provider has screenshots.
  - 36 PNG evidence files total.
  - Duplicate PNG hash scan: 0 duplicate pairs.
- Final matrix: all 8 providers validated through fresh Hub lifecycle. Shop Retail image search remains recorded as an NVIDIA hosted `nvclip` endpoint blocker; all practical local/provider fixes were exhausted for that path.
