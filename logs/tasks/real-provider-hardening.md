# Real Provider Hardening Log

## 2026-05-11 - Phase 0-1

- Removed dependency on `sua-loi-provider/` for runtime testing.
- Reworked hardware snapshot so CPU/RAM/disk are real local values and GPU/VRAM come from `nvidia-smi` when available.
- Removed seeded/fake RTX data from backend responses; unsupported GPU now reports `unknown` instead of fake capacity.
- Added hardware unit tests for parser, missing `nvidia-smi`, and real psutil snapshot behavior.

## 2026-05-11 - Phase 2-3

- Hardened provider runtime script execution with line-by-line log streaming, long task progress, UTF-8 decoding, and Windows read-only delete cleanup.
- Fixed Agentic Commerce upstream Docker build:
  - `f8878cf` in `Agentic-Commerce-blueprint-provider-` pins Node 22 and pnpm 9 for reproducible Docker builds.
- Fixed Warehouse upstream compose:
  - `30470c5` in `Multi-Agent-Intelligent-WarehousePublic-nvidia` makes the local NIM container opt-in via profile so default API mode can boot without local GPU NIM.
- Updated wrappers to create required Docker networks, wait for compose health, use fixed config ports, and avoid UTF-16/NUL PowerShell log output.
- Real lifecycle test passed for both providers: delete clean deploy, install from GitHub, run, health 200, logs readable, stop.

## 2026-05-11 - Phase 4-7

- Removed frontend mock fallback usage from Shell and Hub detail routing; detail pages now fetch backend provider data by `projectId`.
- Added backend benchmark script and dry-run provider lifecycle script.
- Added latency and provider dry-run lifecycle gates to CI.
- Root setup scripts now create `.venv`, install backend dev dependencies there, install frontend dependencies, and seed providers.

## Verification

- Backend: `ruff check .`, `ruff format --check .`, `mypy app`, provider manifest validation, secret scan, pytest coverage 87%, dry-run lifecycle, latency benchmark.
- Frontend: `npm.cmd run typecheck`, `npm.cmd run test`, `npm.cmd run build`.
- Real provider test:
  - `multi-agent-intelligent-warehouse`: fresh clone install 3s, run 30s, health `200`, logs available, stop 6s.
  - `agentic-commerce-blueprint`: fresh clone install 3s, run 69s, health `200`, logs available, stop 15s.
- Backend warm latency p95 stayed around 2-4 ms for health, hardware, provider list, detail, status, logs, and metrics paths.
