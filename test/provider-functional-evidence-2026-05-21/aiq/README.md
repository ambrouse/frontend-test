<div align="center">

# NVIDIA AI-Q Blueprint

![Result](https://img.shields.io/badge/result-PASS-brightgreen?style=for-the-badge)
![Evidence](https://img.shields.io/badge/evidence-screenshots-blue?style=for-the-badge)

</div>

## Run Report

| Field | Value |
| --- | --- |
| Scope | Frontend-visible functionality only |
| Result | PASS |
| Source push status | Pushed source commits 7418832 and 9bfbbdc to origin/develop before final fresh install/retest. |
| Notes | Fresh install after AIQ source push; data sources, README upload, grounded chat answer, Hub lifecycle and logs validated. |

## Evidence Index

| Screenshot | What It Proves |
| --- | --- |
| [01-aiq-home-datasources-loaded.png](./app/01-aiq-home-datasources-loaded.png) | 01 aiq home datasources loaded |
| [01-data-sources-panel.png](./function/01-data-sources-panel.png) | 01 data sources panel |
| [02-file-upload-readme-completed.png](./function/02-file-upload-readme-completed.png) | 02 file upload readme completed |
| [03-file-grounded-chat-answer.png](./function/03-file-grounded-chat-answer.png) | 03 file grounded chat answer |
| [01-hub-running-status.png](./lifecycle/01-hub-running-status.png) | 01 hub running status |
| [01-hub-service-logs-streaming.png](./logs/01-hub-service-logs-streaming.png) | 01 hub service logs streaming |

## Reading Notes

- app proves the provider opened in a real browser.
- function proves visible frontend functions produced results.
- lifecycle proves Hub status/health view for the provider.
- logs proves Hub service-log streaming with live provider output.
