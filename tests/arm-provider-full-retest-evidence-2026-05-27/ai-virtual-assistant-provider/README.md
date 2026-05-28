# AI Virtual Assistant Provider

Status: blocked on ARM by missing required secret.

## Result

- Fresh install from GitHub passed at provider commit `47db4d6`.
- Run failed before app startup because hosted API mode requires `NVIDIA_API_KEY`.
- No provider source fix was made or pushed for this provider in this pass.
- Cleanup passed; `deploy/aiva` was removed.

## Evidence

| Area | Screenshot | Notes |
| --- | --- | --- |
| Blocker | [Missing NVIDIA key](blockers/01-run-missing-nvidia-api-key.png) | Hub progress shows `Error: NVIDIA_API_KEY is missing in .env` |
