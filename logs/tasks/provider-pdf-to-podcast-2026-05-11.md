# 2026-05-11 / 2026-05-14 - Add and harden pdf-to-podcast provider

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
- 2026-05-14: Investigated `Gradio frontend did not become ready at http://127.0.0.1:7860`.
- 2026-05-14: Found the real failure earlier in the install path: Docker image build failed when `pip install` received malformed package-index JSON.
- 2026-05-14: Fixed upstream provider Dockerfiles and `setup.sh`, then pushed `e336a89 fix(setup): retry networked pip installs`.
- 2026-05-14: Stopped the provider stack after verification so a fresh install can be retried from GitHub.

## Verification
- `bash -n` passed for provider Linux scripts.
- PowerShell parser passed for provider Windows scripts.
- `backend/scripts/validate_providers.py` passed with 33 manifests.
- `backend/scripts/provider_dry_run_lifecycle.py` passed for 3 providers.
- Clean runtime health passed: `{"ok":true,"level":"ok","frontendPort":7860,"apiPort":8002}`.
- Cleanup verified: `deploy/pdf-to-podcast` absent and no `pdf-to-podcast` containers listed.
- 2026-05-14: `C:\Program Files\Git\bin\bash.exe -n setup.sh` passed in the upstream clone.
- 2026-05-14: `docker compose -f docker-compose.yaml -f .auto-ports.compose.yaml --env-file .env build` passed for all PDF to Podcast images.
- 2026-05-14: AI Hub Windows run wrapper passed: `{"port":7860,"apiPort":8002,"state":"running"}`.
- 2026-05-14: Health check passed: `{"ok":true,"level":"ok","frontendPort":7860,"apiPort":8002}`.
- 2026-05-14: Metrics reported `9 containers`; final stop left port `7860` closed.

## Notes
- Real podcast generation still requires valid `NVIDIA_API_KEY` and `ELEVENLABS_API_KEY`.
- Health checks intentionally validate service readiness without requiring paid API calls.
- Latest upstream verified commit: `e336a896af960b968a5598357cfed02022798ed9`.
