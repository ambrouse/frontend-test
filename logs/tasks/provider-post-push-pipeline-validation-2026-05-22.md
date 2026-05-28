# Provider Post-Push Pipeline Validation

Date: 2026-05-22

## Scope

Retest all active in-scope providers through the real Hub lifecycle and frontend after clearing provider deploy clones and pushing Hub. Excluded by user scope: `nemotron-voice-agent-provider` and `pdf-to-podcast`.

## Hub Pushes

| Commit | Purpose |
| --- | --- |
| `710e2fd` | Pushed Hub project before the requested fresh validation pass. |
| `94f5416` | First Warehouse hosted model alignment fix. |
| `36ce8a8` | Warehouse unsupported hosted model override fix. |
| `4138ced` | Warehouse model override normalization fix. |
| `48e5297` | Warehouse hosted model write robustness fix. |
| `bdef5c5` | Final Warehouse env passthrough fix; used for the successful fresh retest. |

No provider source repository required a new fix during this post-push validation pass.

## Validation Matrix

| Provider | Lifecycle | Logs | Frontend function | Result |
| --- | --- | --- | --- | --- |
| `agentic-commerce-blueprint` | Real Hub install/run | Service logs visible | Apps SDK search returned tee products | Pass |
| `ai-virtual-assistant-provider` | Real Hub install/run | Service logs visible | Delivery-status chat returned an answer | Pass |
| `aiq` | Real Hub install/run | Service logs visible | README upload plus file-grounded answer | Pass |
| `shop-retail-provider` | Real Hub install/run | Service logs visible | Retail chat returned skirt product results | Pass |
| `multi-agent-intelligent-warehouse` | Real Hub install/run after Hub fix | Service logs visible | Login/dashboard plus forklift maintenance chat output | Pass |
| `web-agent` | Real Hub install/run | Service logs visible | Web search returned answer with visible sources | Pass |

## Evidence

Evidence root: `tests/provider-post-push-pipeline-evidence-2026-05-22/`.

Each provider folder contains:

- `README.md` report.
- `lifecycle/` screenshot and README.
- `logs/` screenshot and README.
- `app/` screenshot and README.
- `function/` pass screenshot(s) and README.

Only `.png` and `.md` files are kept in the final evidence folder.

## Limitations

`aiq` did not validate Tavily/Serper paths because those optional keys were not available in the existing environment. The accepted proof is the file-grounded frontend flow.

`web-agent` did not validate Tavily-specific search. The accepted proof is the SearXNG fallback plus LLM answer with visible sources.

One Warehouse Docker pull hit a transient Cloudflare TLS handshake timeout. A retry completed successfully before the final pass evidence was captured.

## Hygiene Checks

Final checks performed after evidence cleanup:

- Evidence file type scan.
- Duplicate image hash scan.
- Secret pattern scan.
- Git status review before staging.

## Latest-Only Test Folder Cleanup

Time: 2026-05-22

- Removed superseded evidence folder `tests/provider-functional-evidence-2026-05-21/`.
- Kept latest curated evidence folder `tests/provider-post-push-pipeline-evidence-2026-05-22/`.
- Removed local ignored `test/__pycache__/`.
- Updated the legacy smoke helper to write transient output under `test-results/provider-functional-smoke/` so it cannot recreate stale curated evidence under `tests/`.
