# Web Agent

Status: partial pass on ARM.

Fresh source: `deploy/web-agent` cloned from `https://github.com/baolnq-ai/web-agent.git` at `fc38862`.

Result:
- Hub install: pass after Hub wrapper `python3` fallback and safe cleanup fixes.
- Hub run: pass after Hub wrapper invokes the source run script with `bash` because the fresh clone script is not executable.
- Runtime: frontend ready on `http://localhost:3005`; backend health ready on `http://localhost:8011/api/v1/health`; provider SearXNG container started.
- Provider UI: pass; search form renders.
- Search-backed answer: blocked; browser form accepts typed query but does not submit during Playwright validation. Direct backend `/api/v1/search` returned success with zero results from Tavily/SearXNG for the sampled query, so no source-backed answer is counted as pass.

Evidence:
- `lifecycle/01-hub-running-status.png`
- `logs/01-hub-service-logs-streaming.png`
- `logs/02-hub-detailed-logs-streaming.png`
- `app/01-provider-ui-ready.png`
- `blockers/01-ui-search-form-does-not-submit.png`
