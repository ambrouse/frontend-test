# Web Agent

Status: pass.

The provider was installed and run through Hub after the post-push cleanup. The frontend opened on the provider URL, a web search query was submitted, and the chat returned a search-backed answer with visible sources.

## Evidence

| Area | Screenshot | Proof |
| --- | --- | --- |
| Lifecycle | [Hub running status](lifecycle/01-hub-running-status.png) | Hub shows Web Agent running after real install/run |
| Logs | [Service logs streaming](logs/01-hub-service-logs-streaming.png) | Hub service log panel shows provider runtime output |
| App | [Web Agent home](app/01-web-agent-home.png) | Provider frontend opened successfully |
| Function | [Search output with sources](function/01-search-openai-output-with-sources.png) | Search chat returned a summary and source list |

## Key Scope

The existing environment did not include a Tavily key for a Tavily-specific proof. The validated frontend path used the provider's SearXNG fallback plus LLM summary, with sources visible in the UI.

## Fix Loop

No new provider source change was needed in this post-push run. The provider passed after opening the frontend on `localhost`, which avoided a browser cross-origin dev-server issue seen on the numeric loopback URL.

