<div align="center">

# Web Agent

![Result](https://img.shields.io/badge/result-PASS-brightgreen?style=for-the-badge)
![Evidence](https://img.shields.io/badge/evidence-screenshots-blue?style=for-the-badge)

</div>

## Run Report

| Field | Value |
| --- | --- |
| Scope | Frontend-visible functionality only |
| Result | PASS |
| Source push status | Previous source fix already pushed at a908165; remaining dirty source files are unrelated generated/user files and were not pushed. |
| Notes | Frontend search chat with sources, session history, settings key manager, ops/LLM health, Hub lifecycle/logs validated. |

## Evidence Index

| Screenshot | What It Proves |
| --- | --- |
| [01-web-agent-home.png](./app/01-web-agent-home.png) | 01 web agent home |
| [01-search-chat-output-with-sources.png](./function/01-search-chat-output-with-sources.png) | 01 search chat output with sources |
| [02-session-history-list.png](./function/02-session-history-list.png) | 02 session history list |
| [03-settings-tavily-key-manager.png](./function/03-settings-tavily-key-manager.png) | 03 settings tavily key manager |
| [04-ops-dashboard-llm-health.png](./function/04-ops-dashboard-llm-health.png) | 04 ops dashboard llm health |
| [01-hub-running-status.png](./lifecycle/01-hub-running-status.png) | 01 hub running status |
| [01-hub-service-logs-streaming.png](./logs/01-hub-service-logs-streaming.png) | 01 hub service logs streaming |

## Reading Notes

- app proves the provider opened in a real browser.
- function proves visible frontend functions produced results.
- lifecycle proves Hub status/health view for the provider.
- logs proves Hub service-log streaming with live provider output.
