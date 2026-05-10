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
- `GET /api/providers/{provider_id}/status`
- `GET /api/providers/{provider_id}/metrics`
- `GET /api/providers/{provider_id}/logs`
- `GET /api/providers/{provider_id}/config`
- `PATCH /api/providers/{provider_id}/config`
- `POST /api/providers/{provider_id}/install`
- `POST /api/providers/{provider_id}/run`
- `POST /api/providers/{provider_id}/stop`
- `DELETE /api/providers/{provider_id}`
- `GET /api/tasks`
- `GET /api/tasks/active`
- `GET /api/tasks/{task_id}`

## Latency Rules

- Provider and hardware warm paths are covered by pytest latency tests.
- Provider manifests live in `providers/*/aihub.provider.json`.
- Provider registry keeps an in-memory cache and refreshes from disk only after a short TTL.
- Frontend uses lightweight loading/offline states first and fetches backend data with a short timeout; provider/task/hardware data must come from the backend when it is online.
- Provider lifecycle actions are queued in a backend task store. Request handlers return immediately with a task id; long clone, setup, run, stop, or delete work stays off the request path.
- Provider config/status/log/metrics files live under each `providers/{id}/` folder and are small JSON or log files so the UI can poll cheaply.
- Real deploy clones are created only under `deploy/{provider_id}` during install and are removed during delete.
- Warm API latency is guarded by `backend/scripts/benchmark_latency.py`; local p95 is currently under 5 ms for the hot paths.
- Real provider wrappers were tested against fresh GitHub clones into `deploy/`, including install, run, health ping, logs, stop, delete, and install again.

## Provider Lifecycle Body

All lifecycle actions accept the same optional body:

```json
{
  "dryRun": false,
  "force": false,
  "nvidiaApiKey": "optional runtime secret"
}
```

`nvidiaApiKey` is passed only to the child process environment. It is not written to tracked files by the backend. Provider scripts may write local `.env` files during install, and those files are ignored by git.

## Run

```bash
cd backend
python -m pip install -e ".[dev]"
python scripts/seed_providers.py
uvicorn app.main:app --reload
pytest
python scripts/benchmark_latency.py --threshold-ms 100
```
