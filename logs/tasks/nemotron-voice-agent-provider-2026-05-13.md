# Task Log: Nemotron Voice Agent Provider

Date: 2026-05-13 / 2026-05-14

## Summary

- Added `nemotron-voice-agent-provider` Hub wrapper.
- Patched and pushed upstream commit `ad9d920`.
- Verified 3 real Hub lifecycle loops with clone/install/run/metrics/stop/delete.
- 2026-05-14: Investigated `docker compose up failed` during install/run.
- 2026-05-14: Found the actual failure was `python-app` becoming unhealthy because `src.pipeline` import hit a corrupt NLTK `punkt_tab.zip` in the NVIDIA base image.
- 2026-05-14: Patched upstream Dockerfile to refresh NLTK `punkt_tab` and validate imports during build.
- 2026-05-14: Pushed upstream commit `aae4031 fix(docker): refresh NLTK punkt data`.

## Evidence

- Loop 1: install `task-2278e574c99d`, run `task-448e00b3fada`, stop `task-e95d75fe9ca4`.
- Loop 2: run `task-49b057389716`, port `13200`, 2 containers, `gatewayOk=true`.
- Loop 3: run `task-7cb4914c486c`, port `13200`, 2 containers, `gatewayOk=true`.

## Checks

- PowerShell parser: pass.
- Bash parser: pass.
- Provider manifest validation: 39 manifests pass.
- Secret scan: pass.
- 2026-05-14: `docker compose --env-file .env -f docker-compose.yml build python-app` passed.
- 2026-05-14: `python-app` became healthy and `http://127.0.0.1:13260/docs` returned 200.
- 2026-05-14: Hub Windows run wrapper passed with `{"port":13200,"pipelinePort":13260,"state":"running"}`.
- 2026-05-14: Test stack was stopped after verification.
