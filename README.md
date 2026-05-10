# AI Hub

Monorepo for the local AI Hub frontend and provider integration notes.

## Structure

- `frontend/`: Next.js frontend application.
- `docs/`: provider contract and architecture notes.
- `plans/`: implementation plans.
- `logs/`: work logs.

## Frontend

```bash
cd frontend
npm ci
npm run typecheck
npm run test
npm run build
```

PowerShell note: if `npm.ps1` is blocked by execution policy, use `npm.cmd`.

## CI/CD

GitHub Actions runs frontend checks from `frontend/` on Linux and Windows, including x64 and ARM64 runners, then builds a production artifact from `main`.
