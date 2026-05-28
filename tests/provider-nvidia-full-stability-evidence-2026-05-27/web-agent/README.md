# Web Agent

Status: pass.

## Run Report

- Hub pipeline: delete -> fresh install -> run through the live Hub backend and frontend.
- Provider source: `baolnq-ai/web-agent.git` branch `main`, cloned at `3b55b48`.
- Final runtime: frontend `3005`, backend `8011`, SearXNG `6004`.
- Runtime mode: Next.js/FastAPI local dev with NVIDIA-compatible LLM endpoint and SearXNG fallback because no Tavily key is configured.

## Evidence

| Area | File | Result |
| --- | --- | --- |
| Hub lifecycle | [lifecycle/01-hub-running-status.png](lifecycle/01-hub-running-status.png) | Hub shows Web Agent installed/running with frontend `3005` and backend `8011`. |
| Hub logs | [logs/01-hub-detail-fullpage-logs.png](logs/01-hub-detail-fullpage-logs.png) | Hub progress/log view shows fresh run startup, backend and frontend log paths. |
| Provider app | [app/01-web-agent-ui-ready.png](app/01-web-agent-ui-ready.png) | Hub-run provider UI loaded with session history and search input. |
| Web search chat | [function/01-web-search-openai-output-with-sources.png](function/01-web-search-openai-output-with-sources.png) | Frontend created a new session, streamed a web-search answer for OpenAI, and displayed 5 sources with `searxng_fallback`. |

## Fixes Verified

- Provider source `run.sh` now clears stale local dev listeners before starting, preventing Hub health checks from attaching to deleted deploy processes.
- Provider source `run.sh` now exports `API_PROXY_HOST`, `API_PROXY_PORT` and `API_PROXY_TARGET` before `npm run dev`, so Next.js rewrites proxy to backend `8011`.
- Hub wrapper defaults SearXNG to provider-scoped port `6004`; direct SearXNG query and frontend `/search/stream` both passed after fresh reinstall.

## Notes

- Tavily-specific flow was not marked as pass because no Tavily key is configured. The no-key SearXNG fallback path is the provider-supported web-search path and returned real sources through the frontend.
