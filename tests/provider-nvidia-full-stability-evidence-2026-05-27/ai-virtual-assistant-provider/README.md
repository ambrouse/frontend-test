# AI Virtual Assistant Provider

Status: pass.

## Run Report

- Hub pipeline: delete -> fresh install -> run through the live Hub backend and frontend.
- Provider source: `ai-virtual-assistant-provider` commit `6d55b2b` after pushed fixes for ARM-safe UI port and isolated Postgres env defaults.
- Runtime: hosted API mode with local NVIDIA credentials inherited from ignored env files; screenshots and reports are redacted.
- Final status: Hub status API reported `running`, health `ok`, provider UI port `6020`.
- Note: the Hub "Last benchmark" card still displays an older configured benchmark port, but the final Hub progress log, status API and provider app validation all used the active UI on `6020`.

## Evidence

| Area | File | Result |
| --- | --- | --- |
| Hub lifecycle | [lifecycle/01-hub-running-status.png](lifecycle/01-hub-running-status.png) | Provider is installed/running in Hub with container count visible. |
| Hub logs | [logs/01-hub-detail-fullpage-logs.png](logs/01-hub-detail-fullpage-logs.png) | Progress log shows startup completed and active API/UI URLs, including UI `6020`. |
| Provider app | [app/01-provider-ui-ready.png](app/01-provider-ui-ready.png) | AIVA UI loaded with customer data and purchase history. |
| Function output | [function/01-delivery-question-answer.png](function/01-delivery-question-answer.png) | User asks about Shield TV Pro delivery; assistant answers it was delivered using visible purchase history context. |

## Fixes Verified

- Installed amd64 binfmt support on the ARM host so amd64-only UI/support images can run.
- Provider source fix `dae6539`: default UI port moved away from Chrome-blocked port `6000` to `6020`.
- Provider source fix `2b42591`: `.env.example` default UI port updated to `6020`.
- Provider source fix `6d55b2b`: provider env defaults isolate Postgres user/database values from unrelated Hub host env.
- Hub shared wrapper now writes AIVA compose project and Postgres env defaults and cleans `aihub-aiva` compose resources during delete.
