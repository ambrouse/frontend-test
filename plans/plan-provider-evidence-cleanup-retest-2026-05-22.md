# Plan: Provider Evidence Cleanup Retest

- Created: 2026-05-22 15:20
- Updated: 2026-05-22 12:47 +07:00
- Status: closed
- Related log: logs/tasks/provider-evidence-cleanup-retest-2026-05-22.md

## Goal

Retest and clean provider frontend evidence so each in-scope provider folder is readable on GitHub, contains only useful proof, and avoids duplicate/noisy screenshots or technical JSON/TXT/log outputs.

## Scope

- In: `agentic-commerce-blueprint`, `ai-virtual-assistant-provider`, `aiq`, `shop-retail-provider`, `multi-agent-intelligent-warehouse`, `web-agent`.
- In: frontend-visible functions only, Hub status/log proof, unique screenshots, provider README reports.
- In: Agentic Commerce search retest because previous evidence did not prove search.
- Out: `nemotron-voice-agent-provider`, `pdf-to-podcast`.
- Out: backend-only functions not visible from frontend.

## Skills

- fix
- plan-skill
- testing-skill
- readme-style
- logging-skill
- security-skill for secret scan/redaction

## Phases

| Phase | Goal | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Audit current evidence for duplicate images and technical files | done | duplicate hash found in `web-agent/function` |
| 2 | Retest weak evidence, starting with Agentic Commerce search | done | Agentic Commerce search screenshot shows visible result cards and agent result count |
| 3 | Clean evidence folders | done | only README plus unique images remain |
| 4 | Write GitHub-readable provider reports | done | README in evidence root/provider/subfolders |
| 5 | Verify final evidence, logs and secret scan | done | final commands recorded in task log |

## Verification

- Each provider has `README.md`.
- Each provider `app/`, `function/`, `lifecycle/`, and `logs/` folder has a concise `README.md`.
- No `.json`, `.txt`, or `.log` technical evidence files remain under `test/provider-functional-evidence-2026-05-21`.
- No exact duplicate screenshot hashes remain.
- Agentic Commerce has a search screenshot with visible search result evidence.
- Full secret scan over evidence/log/plan/provider folders does not expose the NVIDIA key value.

## Close criteria

- Evidence is clean, grouped, readable on GitHub, and screenshots prove the claimed frontend-visible functions.
- Retest blockers, if any, are documented with exact reason and next action.
- Task log and plan are updated to closed.

## Closure - 2026-05-22

- Result: closed/pass for the six-provider scope.
- Evidence root: `test/provider-functional-evidence-2026-05-21/`.
- Final cleanup kept only screenshots and README reports; no raw JSON/TXT/log evidence files remain.
- Final duplicate hash scan returned no duplicate screenshots.
- Final README scan found no missing local image links, `$sub` placeholders, malformed provider matrix table, or control characters.
- Final secret scan over `test`, `logs`, `plans`, and `providers` returned no `nvapi-...` matches.
- Provider source clone push audit was completed retroactively:
  - `aiq`: pushed `7418832` and `9bfbbdc` to `origin/develop`, then fresh install/run/retest passed.
  - `multi-agent-intelligent-warehouse`: pushed `ae588eb` and `9558b93` to `origin/main`, then fresh install/run/retest passed.
  - `web-agent`: source fix already pushed at `a908165`; remaining dirty files are unrelated/generated and were not pushed.
  - `shop-retail-provider`: source fix already pushed at `8a4ab1e`; latest key-handling change was Hub wrapper only.
  - `agentic-commerce-blueprint`: no provider source clone change in this pass.
  - `ai-virtual-assistant-provider`: no provider source clone change in this pass; only runtime/generated data remains in the clone.
