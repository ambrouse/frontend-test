# Nemotron Voice Agent Provider

Status: partial pass on ARM.

Fresh source: `deploy/nemotron-voice-agent-provider` cloned from `https://github.com/mionm/nemotron-voice-agent-provider.git` at `3a01ebc`.

Result:
- Hub install: pass after shared Linux dispatcher cleanup hardening.
- Hub run: pass after fixing shared dispatcher `wait_http` under `set -u`.
- Runtime: `ui-app` healthy on `http://localhost:9000`; python pipeline docs reachable on `http://localhost:7860/docs`.
- Provider UI: pass; Start action changes the UI into running/stop state.
- Full voice conversation: blocked in this headless ARM environment; UI reports `No voices available` after Start and `Requested device not found` on Configure. No `NVIDIA_API_KEY` or `NGC_API_KEY` is present on the host.

Evidence:
- `lifecycle/01-hub-running-status.png`
- `logs/01-hub-service-logs-streaming.png`
- `logs/02-hub-detailed-logs-streaming.png`
- `app/01-provider-ui-ready.png`
- `function/01-voice-ui-action-result.png`
- `blockers/01-configure-device-not-found.png`
