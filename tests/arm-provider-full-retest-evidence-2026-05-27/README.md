# ARM Provider Full Retest Evidence

Date: 2026-05-27

Machine: ARM/aarch64.

Hub entrypoints:

- Nginx LAN: `http://192.168.2.182/`
- Backend through Nginx: `http://192.168.2.182/api/health`
- Direct frontend dev server: `http://192.168.2.182:3000`
- Direct backend dev server: `http://192.168.2.182:8000`

## Scope

This folder is reserved for fresh provider validation on the current ARM machine. A provider is pass only when its folder contains readable screenshot evidence for lifecycle, logs, app readiness, and each tested function.

## Provider Matrix

| Provider | Status | Evidence |
| --- | --- | --- |
| `agentic-commerce-blueprint` | partial pass; Apps SDK search blocked by missing NVIDIA key | [report](agentic-commerce-blueprint/README.md) |
| `ai-virtual-assistant-provider` | blocked by missing NVIDIA key | [report](ai-virtual-assistant-provider/README.md) |
| `aiq` | blocked by missing NVIDIA key | [report](aiq/README.md) |
| `multi-agent-intelligent-warehouse` | partial pass; local stack/login/equipment pass, chat AI blocked by LLM service connectivity | [report](multi-agent-intelligent-warehouse/README.md) |
| `nemotron-voice-agent-provider` | partial pass; UI/pipeline healthy, full voice conversation blocked by device/voice availability and missing keys | [report](nemotron-voice-agent-provider/README.md) |
| `pdf-to-podcast` | partial pass; source fix pushed, install/run/upload/PDF processing pass, full podcast generation blocked by missing hosted API credentials | [report](pdf-to-podcast/README.md) |
| `shop-retail-provider` | partial pass; install/run/UI/chat accepted, full product-card search not proven without NVIDIA key | [report](shop-retail-provider/README.md) |
| `web-agent` | partial pass; install/run/frontend/backend pass, search-backed answer blocked by non-submitting UI and zero backend results | [report](web-agent/README.md) |

## Evidence Rules

- Keep pass evidence as `.png` screenshots plus `.md` reports.
- Do not keep screenshots that only show loading, pending, empty, or error states as pass evidence.
- Put real failures under `blockers/` with a short explanation and a screenshot where useful.
- Scan for duplicate screenshots, missing README links, and secrets before closing the test pass.
