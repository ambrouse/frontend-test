# 2026-05-11 - Add pdf-to-podcast provider

## Timeline
- Created plan: `plans/plan-add-pdf-to-podcast-provider.md`.
- Cloned `https://github.com/PhuongHo03/pdf-to-podcast.git` into `deploy/pdf-to-podcast`.
- Ran upstream `setup.sh --up`; first run failed because `.env` did not exist.
- Fixed upstream `setup.sh` and pushed:
  - `328261d fix(setup): bootstrap env file automatically`
  - `941b917 fix(setup): honor requested host ports`
- Added AI Hub provider wrapper under `providers/pdf-to-podcast`.
- Added `pdf-to-podcast` to backend dry-run lifecycle coverage.
- Tested clean install/run/health/delete and removed deploy artifacts.

## Verification
- `bash -n` passed for provider Linux scripts.
- PowerShell parser passed for provider Windows scripts.
- `backend/scripts/validate_providers.py` passed with 33 manifests.
- `backend/scripts/provider_dry_run_lifecycle.py` passed for 3 providers.
- Clean runtime health passed: `{"ok":true,"level":"ok","frontendPort":7860,"apiPort":8002}`.
- Cleanup verified: `deploy/pdf-to-podcast` absent and no `pdf-to-podcast` containers listed.

## Notes
- Real podcast generation still requires valid `NVIDIA_API_KEY` and `ELEVENLABS_API_KEY`.
- Health checks intentionally validate service readiness without requiring paid API calls.
