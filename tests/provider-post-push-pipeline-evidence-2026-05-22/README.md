# Post-Push Provider Pipeline Evidence

Date: 2026-05-22

Scope: fresh Hub lifecycle and frontend validation after clearing provider deploy clones, pushing Hub, and retesting every active provider in scope.

## Result

| Provider | Frontend result | Hub lifecycle/logs | Fix loop |
| --- | --- | --- | --- |
| [Agentic Commerce Blueprint](agentic-commerce-blueprint/README.md) | Pass | Pass | No new provider source fix in this post-push run |
| [AI Virtual Assistant](ai-virtual-assistant-provider/README.md) | Pass | Pass | No new provider source fix in this post-push run |
| [AIQ](aiq/README.md) | Pass | Pass | Existing-key scope; file-grounded flow passed |
| [Shop Retail Provider](shop-retail-provider/README.md) | Pass | Pass | No new provider source fix in this post-push run |
| [Multi Agent Intelligent Warehouse](multi-agent-intelligent-warehouse/README.md) | Pass | Pass | Hub wrapper/env fix pushed, then fresh retested |
| [Web Agent](web-agent/README.md) | Pass | Pass | No new provider source fix in this post-push run |

Explicitly skipped by user scope: `nemotron-voice-agent-provider`, `pdf-to-podcast`.

## Pipeline Notes

The validation loop used the real Hub flow: delete existing provider state, install from provider source, run, open Hub detail, verify lifecycle/status/log evidence, open the provider frontend, exercise a real frontend function, capture a pass screenshot, stop the provider, then continue to the next provider.

Hub was pushed before this pass. Warehouse failed first because the runtime container received stale placeholder/model values; Hub fixes were pushed through commit `bdef5c5`, then Warehouse was freshly installed and retested successfully.

No provider source repository required a new fix during this post-push evidence pass. Earlier provider source fixes already recorded in the main plan remain part of the broader validation history.

## Evidence Rules Applied

Only `.png` screenshots and `.md` reports are kept in this folder. Prompt-only, loading-only, duplicate, failed, debug, raw `.txt`, raw `.json`, and raw log artifacts were removed.

Screenshots were read back after capture. The kept function screenshots show real output such as product results, chat answers, grounded file answers, search sources, or warehouse data returned by the app.

## Key Scope

The pass used only keys already available in the environment. Missing optional third-party keys were not treated as blockers when the visible frontend function could pass through an available path:

| Provider | Limitation | Accepted proof |
| --- | --- | --- |
| AIQ | `TAVILY_API_KEY` and `SERPER_API_KEY` were not available | File upload plus file-grounded chat answer |
| Web Agent | Tavily-specific path was not tested | SearXNG fallback plus LLM summary with visible sources |

