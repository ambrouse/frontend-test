# Plan: Provider NVIDIA Full Stability Retest

- Created: 2026-05-27 23:45
- Updated: 2026-05-28 03:05
- Status: done
- Related log: logs/tasks/provider-nvidia-full-stability-retest-2026-05-27.md

## Goal

Retest every active AI Hub provider on this machine through the real frontend/backend Hub pipeline using the local NVIDIA credentials, fix provider-source issues when needed, push those provider fixes, then delete and fresh-install again from Hub until claimed functionality has real screenshot evidence and no fallback-only pass.

## Scope

- In:
  - All active provider wrappers in `providers/`.
  - Hub app runtime through tmux to avoid SSH session hangs.
  - Frontend install/run/status/log views.
  - Provider UI/function smoke tests with visible output evidence.
  - Provider-source fixes, commits, pushes, delete, fresh Hub reinstall and retest when the defect belongs upstream.
  - Evidence cleanup under `tests/provider-nvidia-full-stability-evidence-2026-05-27/`.
  - Redacted local secret handling from `.env`/`.env.local`.
- Out:
  - Publishing secrets, committing `.env`/`.env.local`, or storing token-bearing screenshots/logs.
  - Claiming pass for missing paid third-party-key workflows unless every practical workaround has been tried and blocker evidence is recorded.
  - Reverting unrelated dirty worktree changes.

## Skills

- plan-skill
- logging-skill
- testing-skill
- frontend-skill
- backend-skill
- security-skill
- push-code-skill

## Phases

| Phase | Goal | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Baseline repo, dirty worktree, provider list, env handling, tmux runtime | done | `.env.local` prepared with redacted `NVIDIA_API_KEY`/`NGC_API_KEY`; 8 providers detected |
| 2 | Restart Hub backend/frontend in tmux with proper env and run core checks | done | Hub backend now runs without reload to avoid task loss while cloning `deploy/`; health ok; provider summary 8 ready; manifest validation passed; bash syntax passed; frontend typecheck/test passed |
| 3 | Create clean evidence structure and remove obsolete provider evidence after new folder is ready | done | `tests/provider-nvidia-full-stability-evidence-2026-05-27/README.md` |
| 4 | Retest `agentic-commerce-blueprint` | done | Fresh install at `1932279`; Hub env overwrite bug fixed; delete cleanup hardened; run passed with 13 containers; UI checkout evidence captured |
| 5 | Retest `ai-virtual-assistant-provider` | done | Fresh Hub install at provider commit `6d55b2b`; Hub run passed; app answered delivery question from purchase data; screenshots captured |
| 6 | Retest `aiq` | done | Fresh Hub install/run passed; Knowledge file upload and grounded chat answer evidence captured |
| 7 | Retest `multi-agent-intelligent-warehouse` | done | Fresh Hub install/run passed; dashboard and maintenance chat evidence captured |
| 8 | Retest `nemotron-voice-agent-provider` | done | Fresh Hub install/run passed; WebRTC session and hosted LLM/TTS output evidence captured |
| 9 | Retest `pdf-to-podcast` | done | Provider source fix pushed at `4d0dfdc`; fresh Hub reinstall passed frontend PDF -> transcript -> MP3 generation |
| 10 | Retest `shop-retail-provider` | done | Fresh Hub install/run passed; text retail search evidence captured; NVIDIA nvclip image-search blocker documented |
| 11 | Retest `web-agent` | done | Provider source fixes pushed at `09bd0c7` and `3b55b48`; fresh Hub reinstall passed frontend web-search answer with sources |
| 12 | Hygiene, secret scan, duplicate evidence scan, docs/log close | done | Provider validation passed; backend lifecycle tests passed; secret scan 0 hits; 36 PNGs with 0 duplicate hashes |

## Verification

- Hub:
  - backend health and provider summary through HTTP.
  - frontend dev server ready in tmux.
  - install -> run -> status/logs/service logs -> provider UI/function -> stop/delete/reinstall where fixes are applied.
- Code/tests:
  - backend provider validation and dry-run lifecycle.
  - frontend typecheck/test/build as feasible on this machine.
  - provider wrapper syntax checks.
- Evidence:
  - Each provider folder has `README.md`.
  - Screenshots show input/action and real output/result in the same frame where possible.
  - No kept screenshot is only loading/pending/empty.
  - Duplicate image hash scan, README link scan, and secret scan pass.

## Close criteria

- Every active provider is either fully passing with fresh Hub-installed evidence, or has a documented blocker after practical fixes/workarounds are exhausted.
- Provider-source fixes are pushed upstream before Hub fresh reinstall evidence is counted.
- `tests/` contains the new clean provider evidence set and no obsolete provider evidence clutter.
- Plan/log are updated with final status, commands, results, blockers and residual risks.
