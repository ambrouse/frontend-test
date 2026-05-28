# Agentic Commerce Blueprint

Status: partial pass on ARM.

## Result

- Fresh install from GitHub passed after provider source fix `1932279`.
- Fresh run passed and gateway was healthy on port `8088`.
- Native product catalog and checkout session passed.
- Apps SDK search is blocked because this environment has no `NVIDIA_API_KEY`.
- Stop/delete cleanup passed; no Agentic Commerce containers remained and deploy source was removed.

## Fixes

- Hub wrapper: Linux scripts now use `python3` with `python` fallback.
- Provider source: removed fixed Docker Compose `container_name` values and pushed `1932279 fix: namespace compose containers on ARM 2026-05-27`.

## Evidence

| Area | Screenshot | Notes |
| --- | --- | --- |
| Lifecycle | [Hub running status](lifecycle/01-hub-running-status.png) | Shows installed/running, ARM compatibility, metrics, and progress logs |
| Logs | [Hub service logs](logs/01-hub-service-logs-streaming.png) | Shows Docker service logs from the gateway |
| App | [Provider app ready](app/01-provider-app-ready.png) | Product catalog loaded from the live merchant API |
| Function | [Native checkout session](function/01-native-product-checkout-session.png) | Graphic Tee checkout session and ACP communication completed |
| Blocker | [Apps SDK search missing key](blockers/01-apps-sdk-search-missing-nvidia-key.png) | Search agent unavailable because `NVIDIA_API_KEY` is not configured |
