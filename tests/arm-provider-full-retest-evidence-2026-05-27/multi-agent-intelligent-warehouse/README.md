# Multi-Agent Intelligent Warehouse

Status: partial pass on ARM.

Fresh source: `deploy/multi-agent-intelligent-warehouse` cloned from `https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia` at `d5e0c14`.

Result:
- Hub install: pass after Hub wrapper `python3` fallback fix.
- Hub run: pass; provider script reports backend health, frontend, provider Nginx, default users, and smoke checks passed.
- Provider app: pass at `http://localhost:6010` / direct frontend `http://localhost:6009`.
- Login/dashboard: pass with seeded `admin` user and warehouse data.
- Equipment/assets list: pass with 12 seeded assets.
- Chat AI: blocked; UI returns `Unable to connect to LLM service`, so the AI answer workflow is not counted as pass.

Evidence:
- `lifecycle/01-hub-running-status.png`
- `logs/01-hub-service-logs-streaming.png`
- `logs/02-hub-detailed-logs-streaming.png`
- `app/01-provider-login-ready.png`
- `function/01-login-dashboard-ready.png`
- `function/03-equipment-assets-list.png`
- `blockers/01-chat-llm-service-unavailable.png`
