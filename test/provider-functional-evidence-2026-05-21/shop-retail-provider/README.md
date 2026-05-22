<div align="center">

# Shop Retail Provider

![Result](https://img.shields.io/badge/result-PASS-brightgreen?style=for-the-badge)
![Evidence](https://img.shields.io/badge/evidence-screenshots-blue?style=for-the-badge)

</div>

## Run Report

| Field | Value |
| --- | --- |
| Scope | Frontend-visible functionality only |
| Result | PASS |
| Source push status | No source clone push required for wrapper-only key handling; source clone already at pushed commit 8a4ab1e. |
| Notes | Fresh install/run after key placeholder fix in Hub wrapper; text search, image search, guardrails, reset, Hub lifecycle/logs validated. |

## Evidence Index

| Screenshot | What It Proves |
| --- | --- |
| [01-shop-home-chat-ready.png](./app/01-shop-home-chat-ready.png) | 01 shop home chat ready |
| [01-text-product-search-summer-skirts.png](./function/01-text-product-search-summer-skirts.png) | 01 text product search summer skirts |
| [02-image-upload-similar-shoes-results.png](./function/02-image-upload-similar-shoes-results.png) | 02 image upload similar shoes results |
| [03-guardrails-on-product-care-answer.png](./function/03-guardrails-on-product-care-answer.png) | 03 guardrails on product care answer |
| [04-reset-clears-chat-to-welcome.png](./function/04-reset-clears-chat-to-welcome.png) | 04 reset clears chat to welcome |
| [01-hub-running-status.png](./lifecycle/01-hub-running-status.png) | 01 hub running status |
| [01-hub-service-logs-streaming.png](./logs/01-hub-service-logs-streaming.png) | 01 hub service logs streaming |

## Reading Notes

- app proves the provider opened in a real browser.
- function proves visible frontend functions produced results.
- lifecycle proves Hub status/health view for the provider.
- logs proves Hub service-log streaming with live provider output.
