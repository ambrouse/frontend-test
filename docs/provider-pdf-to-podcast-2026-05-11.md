# 2026-05-11 - PDF to Podcast Provider

## Summary
- Added the `pdf-to-podcast` provider to AI Hub.
- Upstream provider repo: `https://github.com/PhuongHo03/pdf-to-podcast.git`.
- Upstream provider main verified at `941b9171effb8d6a7264d6f73cbcd967f6b06d9d`.

## Provider Fixes
- `setup.sh` now creates `.env` from `.env.example` when missing.
- `setup.sh` now honors caller-provided preferred host ports while still auto-falling forward if a port is busy.

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
