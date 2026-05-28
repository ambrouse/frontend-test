# Nemotron Voice Agent Provider

Status: pass.

## Run Report

- Hub pipeline: delete -> fresh install -> run through the live Hub backend and frontend.
- Provider source: `mionm/nemotron-voice-agent-provider.git` branch `main`, cloned at `3a01ebc`.
- Final runtime: UI `9000`, Python/Pipecat app `7860`.
- Runtime mode: hosted NVIDIA API mode with the local NVIDIA credential loaded from ignored env files.

## Evidence

| Area | File | Result |
| --- | --- | --- |
| Hub lifecycle | [lifecycle/01-hub-running-status.png](lifecycle/01-hub-running-status.png) | Hub shows Nemotron installed/running with healthy container metrics and port `9000`. |
| Hub logs | [logs/01-hub-detail-fullpage-logs.png](logs/01-hub-detail-fullpage-logs.png) | Hub progress/log view shows run completed and Docker services started. |
| Provider app | [app/01-voice-ui-ready.png](app/01-voice-ui-ready.png) | Voice Agent UI loaded with Start and Configure controls. |
| WebRTC session | [function/01-webrtc-session-started.png](function/01-webrtc-session-started.png) | Browser fake-media session connected, bot introduced itself, and language/voice selectors populated. |

## Fixes Verified

- No provider-source fix was required for this run.
- Docker compose started `python-app` and `ui-app` in hosted mode without local NIM services.
- Browser validation used fake microphone permission in headless Chromium; the session opened `/offer`, established WebRTC/data channel, generated an NVIDIA LLM intro and produced hosted TTS output. Full spoken ASR turn was not attempted because this SSH/headless host has no local speech-file generator available, but the ASR processor initialized in the same pipeline session and no fallback UI was used.
