# AI Hub Backend

FastAPI backend for hardware snapshots, provider manifests, runtime status, metrics, logs, and lifecycle tasks.

## Commands

```bash
python -m pip install -e ".[dev]"
python scripts/seed_providers.py
uvicorn app.main:app --reload
pytest
```

The API is cache-first: provider and hardware requests return in-memory snapshots and never run heavy IO on the hot request path.
