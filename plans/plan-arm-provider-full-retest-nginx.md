# Plan: ARM Provider Full Retest and Nginx Compose

- Created: 2026-05-27 17:21
- Updated: 2026-05-27 20:10
- Status: completed
- Related log: logs/tasks/arm-provider-full-retest-nginx-2026-05-27.md

## Goal

Retest every active AI Hub provider on the current ARM/aarch64 machine from real Hub install/run flows, fix or record install/runtime issues, and produce screenshot evidence for every provider function that is claimed as working. Add an Nginx reverse proxy managed by Docker Compose so the Hub can be opened through one stable LAN entrypoint.

## Scope

- In:
  - ARM/aarch64 validation on this machine.
  - All currently seeded providers:
    - `agentic-commerce-blueprint`
    - `ai-virtual-assistant-provider`
    - `aiq`
    - `multi-agent-intelligent-warehouse`
    - `nemotron-voice-agent-provider`
    - `pdf-to-podcast`
    - `shop-retail-provider`
    - `web-agent`
  - Hub lifecycle per provider: delete stale state, install, run, health/status, logs, functional UI test, stop, cleanup check.
  - Screenshot evidence for app ready state, Hub lifecycle/status, service logs, and each provider-specific functional workflow.
  - Blocker screenshots for failures such as ARM image incompatibility, missing key, bad install script, port conflict, or provider UI error.
  - Nginx Docker Compose reverse proxy for frontend and backend.
- Out:
  - Public internet deployment, TLS certificates, domain DNS, production auth hardening.
  - Pushing unrelated refactors or cosmetic changes. Provider source fixes requested by the user are in scope and must be followed by delete plus fresh install verification.
  - Claiming a provider passed without fresh ARM evidence.

## Skills

- plan-skill: plan/status/phase tracking.
- logging-skill: task log and phase evidence summary.
- testing-skill: provider lifecycle, UI evidence, screenshot hygiene.
- backend-skill: backend/CORS and lifecycle API checks.
- frontend-skill: browser/UI checks and responsive screenshot review.
- security-skill: Nginx exposure, CORS scope, secret/evidence hygiene.

## Phases

| Phase | Goal | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Baseline ARM environment, current Hub state, ports, Docker, tmux, provider registry | done | Current machine is `aarch64`; Hub runs on `3000`/`8000`; provider registry reports 8 ready |
| 2 | Add Docker Compose managed Nginx reverse proxy | done | `docker-compose.nginx.yml`, `infra/nginx/templates/aihub.conf.template`, Nginx healthy, frontend/API checks passed via the gateway |
| 3 | Prepare evidence structure and checklist for all providers | done | `tests/arm-provider-full-retest-evidence-2026-05-27/README.md` plus provider report folders |
| 4 | Retest `agentic-commerce-blueprint` on ARM | done | Fresh install/run passed after Hub wrapper fix and provider source push `1932279`; Native checkout evidence captured; Apps SDK search blocked by missing `NVIDIA_API_KEY` |
| 5 | Retest `ai-virtual-assistant-provider` on ARM | done | Fresh install passed at `47db4d6`; run blocked by missing `NVIDIA_API_KEY`; blocker evidence captured; cleanup passed |
| 6 | Retest `aiq` on ARM | done | Fresh install passed at `2ddbbde`; run blocked by missing `NVIDIA_API_KEY`; blocker evidence captured; cleanup passed |
| 7 | Retest `multi-agent-intelligent-warehouse` on ARM | done | Fresh install at `d5e0c14`; run passed local stack and smoke checks; login/dashboard/equipment evidence captured; chat AI blocked by LLM service connectivity |
| 8 | Retest `nemotron-voice-agent-provider` on ARM | done | Fresh install at `3a01ebc`; run passed after shared dispatcher fix; UI/pipeline healthy; full voice conversation blocked by device/voice availability and missing NVIDIA/NGC keys |
| 9 | Retest `pdf-to-podcast` on ARM | done | Fresh install/run passed after provider source push `bbea1b0`; upload and PDF processing passed; full podcast generation blocked by missing hosted API credentials |
| 10 | Retest `shop-retail-provider` on ARM | done | Fresh install at `f2cec9c`; run/UI/chat accepted; product-card search not proven without NVIDIA key |
| 11 | Retest `web-agent` on ARM | done | Fresh install at `fc38862`; run passed after Hub wrapper fixes; frontend/backend pass; search-backed answer blocked by UI non-submit and zero backend results |
| 12 | Evidence hygiene and final report | done | Nginx/API checks passed; 8 manifests valid; frontend typecheck passed; evidence duplicate/temp/secret scans clean |

## Provider Test Checklist

For each provider, do not mark pass until all applicable checks have evidence:

- Hub detail page shows provider installed/running state after real install/run.
- Hub progress/log panel shows provider runtime output, not only stale text.
- Provider frontend opens from the Nginx/LAN entrypoint or documented provider port.
- At least one real provider-specific function completes with visible output:
  - Agentic Commerce: product search/commerce result.
  - AI Virtual Assistant: customer selector plus grounded chat answer.
  - AIQ: data source/readme upload or file-grounded chat answer.
  - Warehouse: login/dashboard plus agent output from warehouse data.
  - Nemotron Voice Agent: UI ready and voice/pipeline interaction where environment permits.
  - PDF to Podcast: upload/process flow or clear blocker if API/key/runtime prevents it.
  - Shop Retail: retail chat/search result with product cards.
  - Web Agent: search-backed answer with visible sources.
- Stop action succeeds or blocker is documented.
- No screenshot kept if it only shows loading, pending, empty, or secret-bearing content.

## Verification

- Nginx:
  - `docker compose -f docker-compose.nginx.yml config`
  - `docker compose -f docker-compose.nginx.yml up -d`
  - `curl -I http://<LAN-IP>/`
  - `curl http://<LAN-IP>/api/health`
- Hub:
  - `GET /api/health`
  - `GET /api/providers/summary`
  - Provider lifecycle through Hub UI/API.
- Evidence hygiene:
  - Only `.png` and `.md` by default under the curated evidence folder.
  - Duplicate image hash scan.
  - README link/file existence scan.
  - Secret pattern scan for API keys/tokens in `tests/`, `logs/`, `plans/`, and provider runtime evidence.

## Close criteria

- Nginx runs under Docker Compose and proxies Hub frontend/backend from the LAN.
- Every active provider has either:
  - pass evidence with screenshots for lifecycle, logs, app, and functions; or
  - blocker evidence with exact failing phase, screenshot/log summary, likely cause, and next fix.
- ARM-specific install/runtime issues are fixed locally where safe or recorded with reproducible steps.
- Plan and log are updated after each phase.
- Final report links to the evidence root and gives a provider-by-provider matrix.
