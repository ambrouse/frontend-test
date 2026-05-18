# Nemotron Voice Agent Provider Integration

Date: 2026-05-13 / 2026-05-14

## Result

`nemotron-voice-agent-provider` is integrated as a real Hub provider. Install clones from `https://github.com/mionm/nemotron-voice-agent-provider.git`; run starts the Python pipeline and UI; health validates the configured Hub gateway and pipeline endpoint; metrics report the live Compose containers.

## Upstream

- Branch: `main`
- Verified commit: `aae4031`
- Upstream fix: UI, Python app, ASR, TTS, and LLM host ports are parameterized for Hub lifecycle.
- Upstream hardening: Docker build now removes stale NLTK `punkt_tab` data from the NVIDIA base image, downloads a clean tokenizer corpus, and validates both pipeline imports before the image is accepted.

## Runtime Contract

- Hub UI port: `13200`
- Pipeline port: `13260`
- Metrics source: Docker Compose container state plus gateway health.
- Runtime config: provider Quick config plus ignored `runtime/config.local.json` for local test secrets.

## Evidence

- Initial clean lifecycle passed: delete `task-372f35e7ab3c`, install `task-2278e574c99d`, run `task-448e00b3fada`, stop `task-e95d75fe9ca4`.
- Repeat loop 2 passed: run `task-49b057389716`, 2 containers, `gatewayOk=true`.
- Repeat loop 3 passed: run `task-7cb4914c486c`, 2 containers, `gatewayOk=true`.
- 2026-05-14 failure investigation: `docker compose up` failed because `python-app` became unhealthy before `ui-app` could start.
- Root cause: `src.pipeline` import failed on a corrupt `/root/nltk_data/tokenizers/punkt_tab.zip`, raising `zipfile.BadZipFile`.
- After upstream commit `aae4031`, `docker compose --env-file .env -f docker-compose.yml build python-app` passed, `python-app` became healthy on port `13260`, and the Hub Windows run wrapper returned `{"port":13200,"pipelinePort":13260,"state":"running"}`.

## Notes

Startup can be slow on a cold Docker cache, so the Hub run harness uses long bounded timeouts with continuous task polling. No secret was committed.
