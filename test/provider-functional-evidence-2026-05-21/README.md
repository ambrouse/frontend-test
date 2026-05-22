<div align="center">

# Provider Functional Evidence

![Status](https://img.shields.io/badge/status-pass-brightgreen?style=for-the-badge)
![Scope](https://img.shields.io/badge/scope-frontend%20functional-blue?style=for-the-badge)
![Date](https://img.shields.io/badge/date-2026--05--22-informational?style=for-the-badge)

Fresh install/run validation evidence for active providers. Scope excludes `nemotron-voice-agent-provider` and `pdf-to-podcast`.

</div>

## Provider Matrix

| Provider | Result | Evidence |
| --- | --- | --- |
| Agentic Commerce Blueprint | PASS | [agentic-commerce-blueprint](./agentic-commerce-blueprint/) |
| NVIDIA AI-Q Blueprint | PASS | [aiq](./aiq/) |
| AI Virtual Assistant Provider | PASS (scoped frontend) | [ai-virtual-assistant-provider](./ai-virtual-assistant-provider/) |
| Multi-Agent Intelligent Warehouse | PASS | [multi-agent-intelligent-warehouse](./multi-agent-intelligent-warehouse/) |
| Shop Retail Provider | PASS | [shop-retail-provider](./shop-retail-provider/) |
| Web Agent | PASS | [web-agent](./web-agent/) |

## Evidence Rules

- Each provider folder is split into app, function, lifecycle, and logs.
- Evidence files are screenshots plus README reports only; no raw JSON/TXT debug output is kept here.
- Screenshots were read back after capture; duplicate hashes and secret patterns were scanned during cleanup.
- Source clone fixes were pushed before fresh install/retest when a provider repo was changed.
