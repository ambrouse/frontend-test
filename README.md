# AI Hub Frontend

Dark-first Next.js frontend for a local AI project hub. The app helps inspect machine resources, browse AI providers, and review project readiness before install/run actions.

## Stack

- [Next.js](https://nextjs.org/) App Router
- [React](https://react.dev/)
- [TypeScript](https://www.typescriptlang.org/)
- [Vitest](https://vitest.dev/)

## Features

- Hardware cockpit for CPU, GPU, RAM, VRAM, disk, temperature, and running tasks.
- Provider Hub with project cards, compatibility ping, search, filter, and project carousel.
- Project detail page with requirements, benchmark, config, logs, and action states.
- Dark/light theme with project-aware ambient backgrounds.
- Mock service layer ready for a backend API adapter.

## Scripts

```bash
npm install
npm run dev
npm run typecheck
npm run test
npm run build
```

PowerShell note: if `npm.ps1` is blocked by execution policy, use `npm.cmd`.

## Project Structure

- `src/app`: Next.js App Router pages.
- `src/components`: UI components.
- `src/services`: mock data, types, compatibility logic.
- `src/utils`: formatting helpers.
- `src/styles`: global design system and theme styles.
- `docs`: task and design documentation.
- `logs`: implementation logs.
- `plans`: implementation plans.

## CI

GitHub Actions runs install, typecheck, tests, and production build on pushes and pull requests to `main`.
