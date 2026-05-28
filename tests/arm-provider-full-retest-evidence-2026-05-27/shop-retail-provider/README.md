# Shop Retail Provider

Status: partial pass on ARM.

Fresh source: `deploy/shop-retail-provider` cloned from `https://github.com/mionm/Shop-Retail-Provider-mion-.git` at `f2cec9c`.

Result:
- Hub install: pass.
- Hub run: pass.
- Runtime: provider Nginx ready at `http://localhost:13000`; stack services started with namespaced Compose project.
- Provider UI: pass; retail assistant loads with category navigation and chat input.
- Chat interaction: partial pass; user prompt is accepted and assistant responds, but the captured response is the scripted assistant guidance rather than product-card search results. Host has no NVIDIA key for full grounded retail generation.

Evidence:
- `lifecycle/01-hub-running-status.png`
- `logs/01-hub-service-logs-streaming.png`
- `logs/02-hub-detailed-logs-streaming.png`
- `app/01-provider-ui-ready.png`
- `function/01-retail-chat-summer-skirts-result.png`
