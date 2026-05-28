# Provider Service Log Streaming

Time: 2026-05-20

## Scope

Implemented Hub service/process log streaming for provider detail pages.

Included provider source mapping for 8 providers:

- `agentic-commerce-blueprint`
- `ai-virtual-assistant-provider`
- `aiq`
- `nemotron-voice-agent-provider`
- `shop-retail-provider`
- `multi-agent-intelligent-warehouse`
- `pdf-to-podcast`
- `web-agent`

Real provider runtime testing intentionally skipped for:

- `nemotron-voice-agent-provider`
- `pdf-to-podcast`

per user instruction.

## What changed

- Added backend service-log response models and endpoints:
  - `GET /api/providers/{id}/service-logs/sources`
  - `GET /api/providers/{id}/service-logs`
  - `DELETE /api/providers/{id}/service-logs`
- Added allowlisted provider log source mapping for Docker Compose, process-file, and hybrid providers.
- Added safe file log clearing for whitelisted provider-owned files.
- Docker logs are exposed as read/clear-view only; Docker daemon logs are not truncated.
- Added frontend `Service logs` tab with source chips, level filtering, search, pause/resume, and clear view/log control.
- Hardened `web-agent` Windows stop wrapper to stop provider-owned processes by deploy path in addition to PID/port fallback.
- Updated API contract tests to expect 8 active providers including `web-agent`.
- Updated provider readiness docs to separate source readiness from the service-log implementation plan.

## Validation

Passed:

- `python -m ruff check backend`
- `python -m ruff format --check backend`
- `python -m mypy backend/app`
- `python -m pytest backend`
- `python backend/scripts/validate_providers.py`
- `python backend/scripts/check_no_secrets.py`
- `npm run test --prefix frontend`
- `npm run typecheck --prefix frontend`
- `npm run build --prefix frontend`

Runtime/API checks:

- Started current backend on `127.0.0.1:8010`.
- Started frontend on `127.0.0.1:3000` against backend `8010`.
- Verified `web-agent` detail route loads.
- Verified service-log source endpoints for all 8 providers.
- Verified dry-run install/run/stop for target providers:
  - `agentic-commerce-blueprint`
  - `ai-virtual-assistant-provider`
  - `aiq`
  - `shop-retail-provider`
  - `multi-agent-intelligent-warehouse`
  - `web-agent`
- Verified `web-agent` running backend health and process service logs from existing deploy runtime.

## Blocked or skipped real runtime checks

Real AI workflow checks for the following providers were blocked because required keys were not present in the environment:

- `agentic-commerce-blueprint`: missing NVIDIA/NGC key.
- `ai-virtual-assistant-provider`: missing NVIDIA/NGC key.
- `aiq`: missing NVIDIA/Tavily/Serper/LLM config.
- `shop-retail-provider`: missing NVIDIA/NGC key.
- `multi-agent-intelligent-warehouse`: missing NVIDIA/embedding/rail key path.
- `web-agent`: backend health and logs were verified; full search/chat smoke blocked by missing Tavily/LLM config.

Skipped by user instruction:

- `nemotron-voice-agent-provider` real runtime test.
- `pdf-to-podcast` real runtime test.

## Follow-up real install/run validation

Time: 2026-05-21

Passed through fresh Hub delete/install/run with health, metrics, and real service-log output:

- `agentic-commerce-blueprint`: gateway `8088` healthy, 13 containers, `nginx` service logs visible. Cleanup had to be re-run once to remove provider-owned `milvus-minio` before the next provider.
- `ai-virtual-assistant-provider`: UI `13301`, API `13300`, 11 containers, `api-gateway-server` logs visible. Initial run was blocked by stale `milvus-minio`; passed after Agentic Commerce cleanup.
- `shop-retail-provider`: gateway `13100`, chain `18109`, 9 containers, `nginx` logs visible. Warmup showed transient 502 before health 200.
- `multi-agent-intelligent-warehouse`: backend `8091`, frontend `3005`, 9 containers, backend service logs visible, login smoke reached 200 OK.
- `web-agent`: backend `8011`, frontend `3005`, process file logs visible after updating default service-log sources to Windows stdout files.

Blocked:

- `aiq`: delete/install completed, but run failed because upstream `setup.sh --up` did not recognize backend readiness on Windows/Git Bash even though the backend was manually healthy at `127.0.0.1:18080/health` and `/v1/jobs/async/agents`. Hub wrapper patches were added for missing Git Bash coreutils after venv activation and attempted Windows port detection; this needs a separate focused fix.

Skipped by user instruction:

- `nemotron-voice-agent-provider`
- `pdf-to-podcast`

## Notes

- Existing `deploy/pdf-to-podcast` has locked `.venv` files, so the global provider dry-run lifecycle script failed during cleanup. That provider was not modified or force-cleaned because user asked not to test it now.
- `web-agent` had an existing running backend from a previous deploy. Service logs were visible through the new API, but the old orphan listener may require manual cleanup outside this task if it persists.

## Existing-key frontend validation

Time: 2026-05-21 11:20 ICT

User scope: keep the existing env keys only. Present key set used for validation: `NVIDIA_API_KEY`; no secret values were written to logs, docs, or screenshots.

Validated through real Hub frontend install/run flows plus service-log UI evidence:

- `agentic-commerce-blueprint`
- `ai-virtual-assistant-provider`
- `aiq`
- `shop-retail-provider`
- `multi-agent-intelligent-warehouse`
- `web-agent`

Skipped by scope, not failed:

- `nemotron-voice-agent-provider`
- `pdf-to-podcast`

Evidence written under `tests/`:

- `provider-frontend-validation-summary.json`
- `provider-frontend-validation-progress.log`
- per-provider screenshots for Install/Run, service logs, pause/resume/search/clear view, detailed logs, and provider app/API pages.

Corrected dynamic-port app evidence after the first capture found stale URLs:

- AIQ backend health and async agents captured on `18081`.
- Shop Retail storefront/API health captured on `13100`, chain health on `18109`.
- Warehouse UI captured on nginx `13003`, backend health on `8091`.
- AI Virtual Assistant UI captured on `13301`, API docs on `13300/docs`; provider wrapper health/metrics remained the health source because bare `/health` on the gateway returns `404`.

Accepted limited-scope items due missing keys:

- AIQ web/paper search requiring `TAVILY_API_KEY`/`SERPER_API_KEY`.
- Agentic Commerce deep checkout/proxy requiring `MERCHANT_API_KEY`/`PSP_API_KEY`.
- Web Agent Tavily-specific live search requiring `TAVILY_API_KEY`.

Cleanup:

- Stopped all six Hub provider runtimes after evidence capture.
- Stopped the `web-agent-searxng` helper container.
- Left unrelated `retail_agent_provider-*` containers untouched because they belong to `C:\code\my source\AI-Agent-retail`, outside this task/workspace.

No provider source clone was modified; no provider repo push was required before this validation pass.

## Closing verification

Time: 2026-05-21 11:45 ICT

Cleanup completed:

- Deleted these six in-scope deploys through Hub API: `agentic-commerce-blueprint`, `ai-virtual-assistant-provider`, `aiq`, `shop-retail-provider`, `multi-agent-intelligent-warehouse`, `web-agent`.
- Confirmed active Hub task count was `0`.
- Confirmed no in-scope provider Docker containers remained running.
- Did not stop/delete `pdf-to-podcast` because it is explicitly out of scope for this pass.
- Did not stop unrelated `retail_agent_provider-*` containers because they belong to `C:\code\my source\AI-Agent-retail`, outside this workspace/task.

Code/test verification passed:

- `python -m ruff check backend`
- `python -m ruff format --check backend`
- `python -m mypy backend\app`
- `python -m pytest backend` (`23 passed`)
- `python backend\scripts\validate_providers.py`
- `python backend\scripts\provider_dry_run_lifecycle.py` (`6 providers`, aligned with current scope)
- `python backend\scripts\benchmark_latency.py --threshold-ms 100`
- `python backend\scripts\check_no_secrets.py`
- PowerShell provider script syntax parse
- Linux provider script syntax parse through Git Bash
- `npm run test --prefix frontend` (`9 passed`)
- `npm run typecheck --prefix frontend`
- `npm run build --prefix frontend`
- Secret artifact scan across generated `tests/`, `logs/`, and `plans/` text files.

Small verification maintenance:

- Updated `backend/scripts/provider_dry_run_lifecycle.py` to remove out-of-scope `pdf-to-podcast` and cover the six scoped providers for dry-run lifecycle verification.

Plan status:

- `plans/plan-provider-service-log-streaming-and-full-validation-2026-05-20.md` marked `closed`.

## Setup rerun fix

Time: 2026-05-21 11:58 ICT

- Fixed `./setup.sh` failure from backend editable install when `backend/logs/` exists.
- Root cause: setuptools flat-layout package discovery saw both `app` and `logs` as top-level packages.
- Fix: constrained backend package discovery to `app*` in `backend/pyproject.toml`.
- Also hardened `setup.sh` on Git Bash/Windows:
  - suppresses the Windows Store `python` alias noise during Python probing.
  - resolves the Windows `py` launcher to a real `python.exe` path when needed.
  - trims CR/whitespace from the NVIDIA key prompt so pressing Enter cannot write an empty `NVIDIA_API_KEY=`.
- Stopped the old `frontend-test` Next dev server processes that were locking `frontend/node_modules/@next/swc-win32-x64-msvc/next-swc.win32-x64-msvc.node`.
- Verified `./setup.sh` completed successfully after the lock was released.
- Removed an empty `.env.local` created by the first prompt test so it will not shadow a real key. User must enter the NVIDIA key again at the next setup prompt if provider validation/run needs it.
- Verification: `bash -n setup.sh` passed; `python -m pytest backend` passed (`23 passed`).

## Final frontend evidence rerun

Time: 2026-05-22 08:05 ICT

User correction applied: test only functions visible on provider frontend, upload files before testing file-grounded flows, and keep only meaningful screenshots split by provider.

Completed in-scope providers:

- `agentic-commerce-blueprint`: catalog, product selection, quantity +/- controls, coupon result, checkout continuation, metrics, client modes, merchant UCP/ACP, Hub running state, and service logs.
- `ai-virtual-assistant-provider`: app load, customer selector, suggested/custom chat responses, manual data download, end chat, Hub running state, and service logs.
- `aiq`: source/file UI, file upload, uploaded file availability, file-grounded question, grounded answer output, Hub running state, and service logs.
- `shop-retail-provider`: category browsing, chat search response with product data, care question, add/view cart, cart total, image upload preview, image search response, Hub running state, and service logs.
- `multi-agent-intelligent-warehouse`: login/dashboard, equipment table/details, forecasting dashboard, operations, safety incident report, document upload, MCP tool search, analytics, chat maintenance answer, Hub running state, and service logs.
- `web-agent`: search chat with visible answer and sources, session history, Tavily key manager fallback state, Ops Dashboard LLM health, Hub running state, and service logs.

Skipped by updated scope:

- `nemotron-voice-agent-provider`
- `pdf-to-podcast`

Evidence root:

- `tests/provider-post-push-pipeline-evidence-2026-05-22/`

Provider source fixes pushed before fresh reinstall:

- `shop-retail-provider`: `8a4ab1e fix catalog retrieval fallback for image search`
- `multi-agent-intelligent-warehouse`: `4d45dac fix: use relative forecasting API URL 2026-05-21`
- `web-agent`: `a908165 fix: preserve frontend env newlines on Windows setup 2026-05-22`

Important findings:

- Warehouse Forecasting originally failed from browser `localhost`/IPv6 split; fixed by using same-origin `/api/v1` for forecasting API calls, then fresh reinstalled and retested.
- Web Agent frontend originally could not call backend because Windows setup wrote `frontend/.env.local` values on one line; fixed provider setup, pushed, fresh reinstalled, and verified `/api/v1/search/stream` is called from the frontend.
- Web Agent has no Tavily key in the current env; accepted path uses SearXNG fallback plus LLM summary and shows real sources in the frontend.
- AIQ remains limited to existing keys: file-grounded knowledge flow passed; web/paper search paths that need `TAVILY_API_KEY`/`SERPER_API_KEY` were not claimed.

Cleanup/security:

- Removed stale/no-output screenshots from the final evidence folders.
- Removed temporary Playwright runner files (`node_modules`, `package*.json`, `test-results`, specs) from evidence folders after capture.
- Redacted generated runtime/log copies of the NVIDIA key from provider runtime artifacts; `.env.local` remains the only local key source for future runs.
