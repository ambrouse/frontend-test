# NVIDIA AI-Q Blueprint

Status: pass.

## Run Report

- Hub pipeline: delete -> fresh install -> run through the live Hub backend and frontend.
- Provider source: `PhuongHo03/aiq.git` branch `develop`, with Hub lifecycle patching applied during install.
- Final runtime: backend `6042`, frontend `6001`, Knowledge API enabled.
- External keys: NVIDIA key available; Tavily and Serper were not available, so web/paper tools registered but reported unavailable. The validated pass path used the built-in Knowledge Layer with uploaded document retrieval.

## Evidence

| Area | File | Result |
| --- | --- | --- |
| Hub lifecycle | [lifecycle/01-hub-running-status.png](lifecycle/01-hub-running-status.png) | Hub shows AI-Q installed/running with 2 agents and backend/frontend ports. |
| Hub logs | [logs/01-hub-detail-fullpage-logs.png](logs/01-hub-detail-fullpage-logs.png) | Hub progress log shows run completed and frontend/backend URLs. |
| Provider app | [app/01-aiq-ui-ready.png](app/01-aiq-ui-ready.png) | AI-Q UI hydrated on `localhost:6001`, data sources loaded and attach enabled. |
| File upload | [function/01-file-upload-completed.png](function/01-file-upload-completed.png) | `aiq-explanation.md` uploaded and marked available. |
| Grounded chat | [function/02-file-grounded-chat-answer.png](function/02-file-grounded-chat-answer.png) | Chat answer cites `aiq-explanation.md` and lists the three technical structure entries from the uploaded file. |

## Fixes Verified

- Hub wrapper now avoids unsafe backend port `6000` by sanitizing AIQ backend port to `6042` and setting provider port minimum to `6001`.
- Hub wrapper now forces frontend `BACKEND_URL`/`NEXT_PUBLIC_BACKEND_URL` to the resolved local backend instead of inheriting unrelated host env.
- Hub wrapper delete/stop scripts now invoke shell scripts via `bash`, so non-executable script files do not break cleanup.
- Provider UI must be opened at the runtime URL advertised by the provider, `http://localhost:6001`; opening via `127.0.0.1` in Next dev mode leaves the client unhydrated because dev-origin protection blocks that host.
