# Provider NVIDIA Full Stability Evidence - 2026-05-27

## Scope

Fresh provider validation on the current Hub machine using the real Hub frontend/backend lifecycle pipeline and local NVIDIA credentials from ignored env files. Credentials are redacted and must not appear in screenshots or reports.

## Provider Matrix

| Provider | Status | Report |
| --- | --- | --- |
| `agentic-commerce-blueprint` | pass | [report](agentic-commerce-blueprint/README.md) |
| `ai-virtual-assistant-provider` | pass | [report](ai-virtual-assistant-provider/README.md) |
| `aiq` | pass | [report](aiq/README.md) |
| `multi-agent-intelligent-warehouse` | pass | [report](multi-agent-intelligent-warehouse/README.md) |
| `nemotron-voice-agent-provider` | pass | [report](nemotron-voice-agent-provider/README.md) |
| `pdf-to-podcast` | pass | [report](pdf-to-podcast/README.md) |
| `shop-retail-provider` | pass with image-search blocker | [report](shop-retail-provider/README.md) |
| `web-agent` | pass | [report](web-agent/README.md) |

## Rules

- Pass screenshots must show a completed behavior with visible output, not only a home page, spinner, pending state, or fallback-only response.
- Provider-source fixes count only after they are pushed upstream, deleted from Hub, freshly installed from GitHub, and retested.
- Blockers are allowed only after practical fixes/workarounds are exhausted and must include concise evidence without secrets.
