# Task Log: Ambient Healthcare Providers

Date: 2026-05-13

## Summary

- Added `ambient-provider-agent` and `ambient-patient-agent` Hub wrappers.
- Patched and pushed upstream commits `1f5c09e` and `f4c553e`.
- Verified 3 real Hub lifecycle loops for each provider.

## Ambient Provider Evidence

- Loop 1: run completed after removing provider port fields from app settings; port `13473`, API port `13400`, 2 containers, `gatewayOk=true`.
- Loop 2: run `task-fe340dd72a6f`, 2 containers, `gatewayOk=true`.
- Loop 3: run `task-65def5456070`, 2 containers, `gatewayOk=true`.

## Ambient Patient Evidence

- Loop 1: install `task-90f046e4fadb`, run `task-80d45e739a9b`, stop `task-40df0ab7755a`.
- Loop 2: run `task-0abc77b6f686`, port `13540`, app `13581`, pipeline `13560`, 2 containers, `gatewayOk=true`.
- Loop 3: run `task-f4715d07bc2e`, port `13540`, app `13581`, pipeline `13560`, 2 containers, `gatewayOk=true`.

## Checks

- PowerShell parser: pass.
- Bash parser: pass.
- Provider manifest validation: 39 manifests pass.
- Secret scan: pass.
