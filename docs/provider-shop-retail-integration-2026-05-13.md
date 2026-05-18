# Shop Retail Provider Integration

Date: 2026-05-13

## Result

`shop-retail-provider` is integrated as a real Hub provider. Install clones from `https://github.com/mionm/Shop-Retail-Provider-mion-.git`, run starts the Docker Compose stack, health verifies the UI gateway, metrics report live containers, and stop/delete clean the deploy directory.

## Upstream

- Branch: `main`
- Verified commit: `6685c86`
- Upstream fix: host ports are parameterized for Hub lifecycle tests.

## Runtime Contract

- Hub port: `13100`
- Chain server port: `18109`
- Metrics source: Docker Compose container state plus gateway health.
- Runtime config: provider Quick config plus ignored `runtime/config.local.json` for local test secrets.

## Evidence

- Initial clean lifecycle passed: install `task-cb08ec252757`, run `task-d9dd1651079b`, stop `task-7ac4497e327e`.
- Repeat loop 2 passed: run `task-e78688113ed4`, 9 containers, `gatewayOk=true`.
- Repeat loop 3 passed: run `task-add88514b35a`, 9 containers, `gatewayOk=true`.

## Notes

All long lifecycle commands were run through the Hub task API with explicit per-action timeouts and status polling. No secret was committed.
