# Ambient Healthcare Agents Archive

Date: 2026-05-18

## Result

`ambient-provider-agent` and `ambient-patient-agent` were removed from the active AI Hub provider catalog during the seven-provider cleanup.

## Current Status

These provider IDs are no longer active Hub providers:

- `ambient-provider-agent`
- `ambient-patient-agent`

The backend registry, frontend fallback data, and provider dispatch scripts should not expose them as installable providers. Historical lifecycle notes remain useful only as archive context.

## Active Provider Policy

AI Hub currently keeps exactly these seven provider wrappers under `providers/`:

- `agentic-commerce-blueprint`
- `ai-virtual-assistant-provider`
- `aiq`
- `nemotron-voice-agent-provider`
- `shop-retail-provider`
- `multi-agent-intelligent-warehouse`
- `pdf-to-podcast`

## Safety Notes

Healthcare workflows can include PHI/PII. Historical logs and docs should not include request payloads, patient data, tokens, or runtime secrets.
