# AIQ

Status: blocked on ARM by missing required secret.

## Result

- Fresh install from GitHub passed at provider commit `2ddbbde`.
- Run failed before app startup because hosted knowledge mode requires `NVIDIA_API_KEY`.
- No provider source fix was made or pushed for this provider in this pass.
- Hub wrapper was fixed locally to use `python3` with `python` fallback.
- Cleanup passed; `deploy/aiq` was removed.

## Evidence

| Area | Screenshot | Notes |
| --- | --- | --- |
| Blocker | [Missing NVIDIA key](blockers/01-run-missing-nvidia-api-key.png) | Hub progress shows `[setup] Missing NVIDIA_API_KEY in deploy/.env` |
