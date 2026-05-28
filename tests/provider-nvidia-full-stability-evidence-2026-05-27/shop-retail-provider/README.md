# Shop Retail Provider

Status: pass with image-search blocker.

## Run Report

- Hub pipeline: delete -> fresh install -> run through the live Hub backend and frontend.
- Provider source: `mionm/Shop-Retail-Provider-mion-.git` branch `main`, cloned at `f2cec9c`.
- Final runtime: nginx/UI `13000`, chain server `18109`, catalog retriever `18110`, memory retriever `18111`, guardrails `18112`.
- Runtime mode: NVIDIA hosted LLM/embedding/rails endpoints with local Milvus/MinIO.

## Evidence

| Area | File | Result |
| --- | --- | --- |
| Hub lifecycle | [lifecycle/01-hub-running-status.png](lifecycle/01-hub-running-status.png) | Hub shows Shop Retail installed/running on port `13000`. |
| Hub logs | [logs/01-hub-detail-fullpage-logs.png](logs/01-hub-detail-fullpage-logs.png) | Hub progress/log view shows compose startup completed. |
| Provider app | [app/01-shop-home-ready.png](app/01-shop-home-ready.png) | Retail UI loaded with category tabs, assistant panel and chat input. |
| Text retail search | [function/01-text-search-summer-skirts-output.png](function/01-text-search-summer-skirts-output.png) | Assistant answered a summer-skirt query with product names, prices and product cards. |

## Fixes Verified

- Hub shared wrapper now sources the hydrated deploy `.env` before `docker compose up` for Shop Retail, so empty Hub env placeholders do not override populated NVIDIA-derived keys.
- Fresh Hub reinstall after the wrapper fix showed chain server using a non-empty `LLM_API_KEY` and catalog retriever using a non-empty `EMBED_API_KEY`.
- Text embeddings populated successfully through NVIDIA hosted embeddings; text retail search passed.

## Blocker

- Image search is blocked by the current NVIDIA `nvclip` hosted embedding endpoint returning `400 Bad Request` with `DEGRADED function cannot be invoked`.
- This is not a missing local key issue; the same NVIDIA credential works for LLM and text embeddings in this provider. Image-search evidence is therefore recorded as an external service blocker for this run.
