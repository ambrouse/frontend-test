# Backend API Notes

Date: 2026-05-10

## Purpose

The backend provides low-latency cached data for the frontend. Requests should return from memory snapshots and avoid heavy filesystem or hardware probing on the request path.

## Current Endpoints

- `GET /api/health`
- `GET /api/hardware/snapshot`
- `GET /api/providers`
- `GET /api/providers/featured`
- `GET /api/providers/summary`
- `GET /api/providers/{provider_id}`
- `GET /api/tasks`
- `GET /api/tasks/active`

## Latency Rules

- Provider and hardware warm paths are covered by pytest latency tests.
- Provider manifests live in `providers/*/aihub.provider.json`.
- Provider registry keeps an in-memory cache and refreshes from disk only after a short TTL.
- Frontend uses static fallback data first and fetches backend data with a short timeout, so backend startup or IO cannot block the first paint.

## Run

```bash
cd backend
python -m pip install -e ".[dev]"
python scripts/seed_providers.py
uvicorn app.main:app --reload
pytest
```
