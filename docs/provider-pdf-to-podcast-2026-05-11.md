# 2026-05-11 / 2026-05-14 - PDF to Podcast Provider

## Summary
- Added the `pdf-to-podcast` provider to AI Hub.
- Upstream provider repo: `https://github.com/PhuongHo03/pdf-to-podcast.git`.
- Upstream provider main verified at `e336a896af960b968a5598357cfed02022798ed9`.

## Provider Fixes
- `setup.sh` now creates `.env` from `.env.example` when missing.
- `setup.sh` now honors caller-provided preferred host ports while still auto-falling forward if a port is busy.
- `setup.sh` now retries local `uv pip install` operations so transient package-index failures do not break install.
- Service Dockerfiles now retry networked `pip install` operations with `--no-cache-dir`, longer timeout, and pip retries.

## Hub Integration
- Added `providers/pdf-to-podcast/aihub.provider.json`.
- Added Windows and Linux lifecycle scripts for setup, run, stop, delete, health, and metrics.
- Added dry-run support so CI lifecycle checks can validate the provider without starting Docker.

## Verification
- Fresh upstream clone failed before fix because `.env` was missing.
- After upstream fixes, `setup.sh --up` started the full provider stack.
- Hub wrapper clean install/run/health/delete passed on Windows.
- Final health passed on frontend `7860` and API `8002`.
- Final cleanup removed `deploy/pdf-to-podcast` and no `pdf-to-podcast` containers remained.
- On 2026-05-14, reproduced a later failure where Docker image builds stopped at `pip install` after malformed package-index JSON.
- After upstream commit `e336a89 fix(setup): retry networked pip installs`, full Docker Compose build passed for all provider images.
- AI Hub Windows run wrapper passed again with `{"port":7860,"apiPort":8002,"state":"running"}`.
- Health check passed again with `{"ok":true,"level":"ok","frontendPort":7860,"apiPort":8002}`.
