# Run Project via tmux and Linux Provider Stability Check - 2026-05-27

## Time

- Start: 2026-05-27 17:00 +07
- Finish: 2026-05-27 17:04 +07

## Task

- Run AI Hub locally using the README Linux/macOS commands inside tmux.
- Check which provider set has current Linux wrapper/evidence confidence.

## Actions

- Read root, frontend, and backend README files.
- Confirmed the current README has Linux/macOS run commands but no literal `tmux` section.
- Ran `./setup.sh`; backend `.venv`, frontend dependencies, and provider seed completed.
- Started tmux session `ai-hub`:
  - window `backend`: `./.venv/bin/python -m uvicorn app.main:app --reload --app-dir backend`
  - window `frontend`: `cd frontend && npm run dev`
- Verified:
  - Backend health: `GET http://127.0.0.1:8000/api/health` returned `{"ok":true}`.
  - Provider summary: `8` total, `8` ready, `0` blocked.
  - Frontend: `http://127.0.0.1:3000` returned HTTP `200`.
  - Linux script syntax: `bash -n setup.sh` and all `providers/*/scripts/linux/*.sh` passed.
  - Provider manifest validation: `Validated 8 provider manifests`.
  - Dry-run lifecycle: passed for 6 in-scope providers.

## Provider Stability Notes

- Current strongest Linux-ready set by dry-run lifecycle and post-push evidence:
  - `agentic-commerce-blueprint`
  - `ai-virtual-assistant-provider`
  - `aiq`
  - `shop-retail-provider`
  - `multi-agent-intelligent-warehouse`
  - `web-agent`
- `nemotron-voice-agent-provider` and `pdf-to-podcast` are present in manifests and Linux syntax passed, but they were explicitly outside the latest post-push evidence scope and not part of the current dry-run lifecycle script.

## Notes

- Setup seeded `8` providers; this includes `web-agent`. The root README active table was updated on 2026-05-28 to match this count.
- Setup/dry-run produced local runtime files under provider runtime directories; these are local generated artifacts.

## LAN IP Access Update

- User asked whether the app can be opened by IP.
- Updated backend CORS to allow localhost plus private LAN browser origins on Next.js dev ports.
- Recreated tmux session `ai-hub` with:
  - backend: `uvicorn ... --host 0.0.0.0`
  - frontend: `NEXT_PUBLIC_API_BASE=http://192.168.2.182:8000 npm run dev -- --hostname 0.0.0.0`
- Verified:
  - `http://192.168.2.182:8000/api/health` returned `{"ok":true}`.
  - `http://192.168.2.182:8000/api/providers/summary` returned `8` total and `8` ready with Origin `http://192.168.2.182:3000`.
  - `http://192.168.2.182:3000` returned HTTP `200`.
  - `ruff check backend/app/main.py` passed.
