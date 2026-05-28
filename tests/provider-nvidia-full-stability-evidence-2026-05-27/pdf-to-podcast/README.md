# PDF to Podcast

Status: pass.

## Run Report

- Hub pipeline: delete -> fresh install -> run through the live Hub backend and frontend.
- Provider source: `PhuongHo03/pdf-to-podcast.git` branch `main`, fixed and retested at `4d0dfdc`.
- Final runtime after fresh install: Gradio frontend `7861`, API service `8003`.
- Runtime mode: NVIDIA hosted LLM plus Edge TTS fallback because no ElevenLabs key is configured.

## Evidence

| Area | File | Result |
| --- | --- | --- |
| Hub lifecycle | [lifecycle/01-hub-running-status.png](lifecycle/01-hub-running-status.png) | Hub shows PDF to Podcast installed/running with 10 containers and frontend `7861`. |
| Hub logs | [logs/01-hub-detail-fullpage-logs.png](logs/01-hub-detail-fullpage-logs.png) | Hub progress/log view shows fresh run completed and auto-selected ports. |
| Provider app | [app/01-gradio-ui-ready.png](app/01-gradio-ui-ready.png) | Gradio UI loaded from the Hub-run frontend. |
| Frontend generation progress | [function/01-generation-running-from-frontend.png](function/01-generation-running-from-frontend.png) | UI shows uploaded `sample.pdf`, monologue mode and live PDF/agent progress. |
| Frontend generation output | [function/02-generation-completed-from-frontend.png](function/02-generation-completed-from-frontend.png) | UI shows completed MP3, transcript JSON and generation-history JSON after PDF -> agent -> TTS. |

## Fixes Verified

- Provider source commit `4d0dfdc` passes Edge fallback voice settings into the Gradio frontend container, so frontend jobs no longer submit stale ElevenLabs voice IDs when ElevenLabs is not configured.
- Provider source commit `4d0dfdc` also applies the validated fallback voice mapping inside TTS processing, so invalid submitted voices are not reused after fallback selection.
- Fresh Hub install after push cloned `4d0dfdc`; the pass evidence was captured only after that reinstall.
