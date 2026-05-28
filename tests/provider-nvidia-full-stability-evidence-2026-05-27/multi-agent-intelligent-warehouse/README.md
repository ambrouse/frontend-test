# Multi-Agent Intelligent Warehouse

Status: pass.

## Run Report

- Hub pipeline: delete -> fresh install -> run through the live Hub backend and frontend.
- Provider source: `PhuongHo03/multi-agent-intelligent-warehouse.git` branch `main`, with Hub wrapper port fixes applied during install.
- Final runtime: frontend `6009`, backend `6008`, nginx `6010`.
- Health: backend `/api/v1/health` reported healthy database, Redis and Milvus services.

## Evidence

| Area | File | Result |
| --- | --- | --- |
| Hub lifecycle | [lifecycle/01-hub-running-status.png](lifecycle/01-hub-running-status.png) | Hub shows MAIW installed and running on the corrected frontend port. |
| Hub logs | [logs/01-hub-detail-fullpage-logs.png](logs/01-hub-detail-fullpage-logs.png) | Hub progress/log view shows setup/run completed and exposed URLs. |
| Provider app | [app/01-login-screen-ready.png](app/01-login-screen-ready.png) | Provider login screen loaded from the Hub-run frontend. |
| Dashboard | [function/01-dashboard-after-login.png](function/01-dashboard-after-login.png) | Authenticated dashboard shows online system status, 12 equipment assets and 2 maintenance-needed assets. |
| Agent chat | [function/02-chat-maintenance-output.png](function/02-chat-maintenance-output.png) | Chat assistant answered the maintenance query with FL-03 and HUM-01 and showed structured equipment data. |

## Fixes Verified

- Hub wrapper now defaults the provider UI to `6009` instead of browser-unsafe port `6000`.
- Hub wrapper now defaults/sanitizes the backend to `6008` and nginx to `6010`, avoiding conflicts with internal service ports.
- Run and metrics scripts export the resolved frontend/backend ports consistently, so Hub status, provider health and screenshots all point at the same running instance.
