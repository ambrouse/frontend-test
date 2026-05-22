# Plan: Seven Provider Delete Image Cleanup and Real Validation

Date: 2026-05-19

## Goal

Make Hub provider deletion fully clean the local machine for all seven active providers: provider containers, provider volumes, provider networks, and provider-owned Docker images must be removed after Hub delete. Any fix that belongs inside provider source must be made in the provider repository itself, tested, committed, pushed, then validated through a fresh Hub install that clones the pushed source. Validation must prove the provider runs real functionality with real API calls and real results; no fallback-only pass is acceptable.

## Scope

Active providers:

1. `agentic-commerce-blueprint`
   - Source repo: `https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-`
   - Branch: `main`
   - Hub install dir: `deploy/agentic-commerce-blueprint`
   - Main runtime: Docker Compose, gateway `8088`
2. `ai-virtual-assistant-provider`
   - Source repo: `https://github.com/mionm/ai-virtual-assistant-provider.git`
   - Branch: `main`
   - Hub install dir: `deploy/aiva`
   - Main runtime: Docker Compose, UI `13001`, agent health `9000`
3. `aiq`
   - Source repo: `https://github.com/PhuongHo03/aiq.git`
   - Branch: `develop`
   - Hub install dir: `deploy/aiq`
   - Main runtime: local Python/Node services, API health `18080`, UI `13080`
4. `nemotron-voice-agent-provider`
   - Source repo: `https://github.com/mionm/nemotron-voice-agent-provider.git`
   - Branch: `main`
   - Hub install dir: `deploy/nemotron-voice-agent-provider`
   - Main runtime: Docker Compose, UI `9000`, pipeline `7860`
5. `shop-retail-provider`
   - Source repo: `https://github.com/mionm/Shop-Retail-Provider-mion-.git`
   - Branch: `main`
   - Hub install dir: `deploy/shop-retail-provider`
   - Main runtime: Docker Compose, gateway `13000`, chain server `18109`
   - Current provider source push already done: `62352a0 fix hub compose isolation and chat defaults`
6. `multi-agent-intelligent-warehouse`
   - Source repo: `https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia`
   - Branch: `main`
   - Hub install dir: `deploy/multi-agent-intelligent-warehouse`
   - Main runtime: Docker Compose, API `8091`, UI `13002`
7. `pdf-to-podcast`
   - Source repo: `https://github.com/PhuongHo03/pdf-to-podcast.git`
   - Branch: `main`
   - Hub install dir: `deploy/pdf-to-podcast`
   - Main runtime: Docker Compose, Gradio `7860`, API `8002`

## Required Skills

- `backend-skill`: Hub provider runtime endpoints, lifecycle API, provider script execution, status and metrics contracts.
- `frontend-skill`: Hub UI delete/install/run flows, provider detail page, real interaction smoke checks where UI is required.
- `testing-skill`: strict phase gate, real integration tests, negative checks for cleanup residue, no false fallback pass.
- `documentation-skill`: final docs under `docs/` only when implementation changes require user-facing or operations documentation.
- `logging-skill`: task log under `logs/tasks/` with exact validation outcomes and no secrets.
- `security-skill`: secret handling, real API-key use without printing values, no `.env` or token commits.
- `push-code-skill`: commit/push Hub repo and each provider repo separately, with clear messages and CI awareness.

## Global Rules

- Do not print, commit, or log API key values. Only record presence/length or pass/fail.
- Do not commit `.env`, `.env.local`, deploy runtime configs containing secrets, provider logs, Docker volumes, or generated artifacts.
- If source under a cloned provider repo is changed, commit and push that provider repo before validating fresh Hub install.
- Hub wrappers may patch environment and call lifecycle scripts, but provider-owned Docker cleanup logic must live in provider source when the provider source owns the compose stack.
- No provider is considered pass if it only boots a fallback, dry-run, mocked response, or static UI. Each provider needs a real API-backed function check appropriate to its domain.
- Delete pass requires checking Docker state before and after: containers, volumes, networks, images, and build cache residue relevant to the provider.
- Each provider phase must complete: inspect -> fix -> source test -> push -> Hub fresh clone install -> run -> real function -> delete -> cleanup verification -> log.

## Definition of Done

The task is 100% complete only when all are true:

1. Hub delete removes provider containers, volumes, networks, and provider-owned images for all seven providers.
2. Each provider with source changes has a pushed provider-repo commit.
3. Hub repo has wrapper/manifest/test/docs/log changes committed and pushed.
4. A fresh Hub install is run after provider pushes for every provider.
5. Each provider starts from the fresh clone and passes health/metrics checks.
6. Each provider passes a real domain function check using real APIs where required.
7. Each provider delete is run through Hub and leaves no provider-owned Docker resources behind.
8. Backend provider tests, frontend relevant tests/typecheck, provider manifest validation, and cleanup regression checks pass.
9. Logs and docs are updated without secrets.

## Phase 0: Preflight and Safety Baseline

Estimated time: 45-75 minutes.

Steps:

1. Check current git status for Hub and verify no secret files are staged.
2. Confirm Docker Desktop/daemon is running and record Docker version, Compose version, available disk, and current provider-related Docker resources.
3. Confirm required real API keys are present in environment or root `.env.local` without printing values:
   - `NVIDIA_API_KEY` for NVIDIA-backed providers.
   - `NGC_API_KEY` where required; may map from NVIDIA key only if provider supports it.
   - `TAVILY_API_KEY` and `SERPER_API_KEY` for full AI-Q source-mode validation if available.
   - `ELEVENLABS_API_KEY` or provider-specific TTS key for PDF-to-Podcast real audio validation if required by provider.
4. Inventory seven provider manifests and lifecycle scripts.
5. Create a cleanup snapshot file outside commits or a sanitized log summary with only resource names/counts, not secrets.

Testing gate:

- `git status` reviewed.
- `docker info` and `docker compose version` pass.
- Secret presence checked without value output.
- Baseline resource inventory captured.

## Phase 1: Hub Cleanup Contract and Test Harness

Estimated time: 2-3 hours.

Goal:

Add or harden Hub-side tests that enforce delete cleanup behavior across providers without relying only on manual testing.

Steps:

1. Inspect backend provider runtime delete flow.
2. Ensure delete commands route to provider-specific cleanup scripts and do not kill unrelated Hub frontend/backend processes.
3. Add/adjust backend tests so each seven-provider delete command is covered for:
   - `docker compose down --volumes --remove-orphans --rmi all` where Docker Compose owns images.
   - Safe deploy-directory deletion inside allowed deploy root only.
   - No cleanup outside provider deploy dir.
   - No shared process auto-kill that can stop Hub frontend.
4. Add a lightweight script or test helper to list provider-owned Docker resources by labels/name prefixes.
5. Add a regression check that no provider script still uses `--rmi local` unless explicitly justified.
6. Add CI/local validation commands to run provider manifest validation and cleanup contract tests.

Testing gate:

- Backend provider runtime/lifecycle tests pass.
- Provider manifest validation passes.
- Grep/check confirms no stale `--rmi local` in active provider delete paths.
- No secret or deploy artifact staged.

## Phase 2: Provider 1 - Agentic Commerce Blueprint

Estimated time: 4-7 hours, depending on Docker build time.

Provider source repo: `https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-`

Steps:

1. Clone fresh source repo into a temporary working directory or install through Hub into `deploy/agentic-commerce-blueprint`.
2. Inspect source compose files for fixed image names, build tags, container names, network names, and labels.
3. Determine whether cleanup should be fixed in source repo, Hub wrapper, or both.
4. If source needs change:
   - Add provider-owned Compose project name or labels if missing.
   - Ensure delete/cleanup script removes provider Compose resources with `down --volumes --remove-orphans --rmi all`.
   - Ensure images built by compose are removable and identifiable.
   - Commit and push source repo.
5. Run source-level validation:
   - Compose config validation.
   - Build or pull required images.
   - Run stack.
6. Real function validation:
   - Open/health-check storefront/API.
   - Submit a real commerce/agent query that reaches NVIDIA-backed agent path.
   - Confirm response is generated, not static fallback.
   - Confirm relevant service logs show a real request path without logging key values.
7. Hub fresh clone validation:
   - Delete any previous deploy.
   - Install from Hub after provider source push.
   - Run from Hub UI/API.
   - Repeat health, metrics, and real commerce query.
8. Delete validation:
   - Delete from Hub.
   - Verify provider containers, volumes, networks, and provider-owned images are gone.
   - Verify Hub frontend/backend still running.

Pass criteria:

- Fresh clone installs and runs.
- Real commerce agent response succeeds.
- Delete leaves no Agentic Commerce provider Docker resources.

## Phase 3: Provider 2 - AI Virtual Assistant Provider

Estimated time: 4-8 hours.

Provider source repo: `https://github.com/mionm/ai-virtual-assistant-provider.git`

Steps:

1. Clone/install fresh provider source.
2. Inspect compose source and generated Hub override files.
3. Fix source cleanup if provider source owns cleanup scripts or compose metadata.
4. Confirm Hub-generated overrides do not create orphan images without labels/project ownership.
5. Source-level validation:
   - Compose config with `.env` and Hub override files.
   - Build/run hosted API mode with CPU Milvus override where configured.
6. Real function validation:
   - Check UI `13001` and agent health `9000`.
   - Send a real customer-service assistant request through provider API/UI.
   - Confirm response is produced by real NVIDIA-backed agent path, not fallback.
7. Push provider source changes if any.
8. Fresh Hub install validation after push.
9. Hub delete and Docker resource cleanup verification.

Pass criteria:

- Hosted assistant flow produces a real answer.
- Delete removes AI Virtual Assistant containers, volumes, networks, images.
- No stale override or runtime artifact is committed.

## Phase 4: Provider 3 - NVIDIA AI-Q Blueprint

Estimated time: 4-8 hours.

Provider source repo: `https://github.com/PhuongHo03/aiq.git`, branch `develop`

Special note:

The manifest currently says direct upstream push may be blocked by GitHub permissions. If push is blocked, document the blocker, keep Hub patching safe, and provide a branch/patch artifact only if it does not include secrets. If push is possible, push the provider source fix.

Steps:

1. Clone branch `develop` fresh.
2. Inspect whether AI-Q uses Docker images in Hub mode; if not, define cleanup for Python/Node runtime processes plus any optional Docker support services.
3. Confirm delete does not kill unrelated processes and removes AI-Q-specific runtime dirs safely.
4. If source changes are needed and push is permitted:
   - Apply source fix.
   - Test source.
   - Commit and push to provider repo.
5. Source-level validation:
   - Python environment/bootstrap.
   - UI build/run if applicable.
   - API health on `18080`, UI on `13080`.
6. Real function validation:
   - Run a real AI-Q async research/knowledge job through API.
   - If Tavily/Serper keys exist, validate full source/web/paper search path.
   - If optional keys are absent, validate built-in Knowledge API path with NVIDIA LLM response and explicitly record missing optional keys without exposing values.
7. Fresh Hub install after provider source push or Hub patch.
8. Hub delete validation:
   - No AI-Q processes remain.
   - No AI-Q Docker resources remain if optional Docker services were started.
   - Ports `13080` and `18080` are free.

Pass criteria:

- Real AI-Q job completes with generated result.
- Cleanup removes AI-Q runtime/process/Docker residue.

## Phase 5: Provider 4 - Nemotron Voice Agent Provider

Estimated time: 4-8 hours.

Provider source repo: `https://github.com/mionm/nemotron-voice-agent-provider.git`

Steps:

1. Clone/install source fresh.
2. Inspect compose image names, project name, networks, volumes, and provider cleanup scripts.
3. Fix source cleanup if needed, especially compose image removal and project isolation.
4. Source-level validation:
   - Compose config.
   - Run `python-app` and `ui-app` in hosted API mode.
   - Health check pipeline `7860` and UI `9000`.
5. Real function validation:
   - Exercise voice pipeline endpoint or WebRTC-adjacent API using hosted ASR/TTS/LLM where available.
   - Confirm real NVIDIA endpoint interaction by successful generated response/audio/transcript path.
   - If browser microphone is not automatable, use provider API endpoint equivalent and document limitation.
6. Commit/push provider source if changed.
7. Fresh Hub install/run after push.
8. Delete and verify images/containers/volumes/networks removed.

Pass criteria:

- Hosted voice-agent pipeline produces real response or audio/transcript result.
- Delete cleans all Nemotron Docker resources.

## Phase 6: Provider 5 - Shop Retail Provider

Estimated time: 3-5 hours because source isolation fix is already pushed.

Provider source repo: `https://github.com/mionm/Shop-Retail-Provider-mion-.git`

Known source commit already pushed:

- `62352a0 fix hub compose isolation and chat defaults`

Steps:

1. Pull latest provider repo and confirm commit `62352a0` is in `main`.
2. Confirm compose has no fixed `container_name` and no fixed network name.
3. Confirm nginx timeout and guardrails default source changes exist.
4. Run source-level compose config and build/run.
5. Real function validation:
   - UI/API health on `13000`.
   - Chain health on `18109`.
   - Chat with guardrails off returns real generated shopping assistant response.
   - Chat with guardrails on returns real generated response through rails checks.
6. Fresh Hub install:
   - Delete local deploy.
   - Install from Hub so it clones commit `62352a0` or newer.
   - Run provider.
   - Repeat real chat tests.
7. Delete validation:
   - Hub delete removes `aihub-shop-retail-provider-*` containers/images/volumes/networks.
   - Verify no Shop Retail images remain by project/name filters.

Pass criteria:

- Real chat passes with guardrails off and on.
- Fresh Hub clone includes pushed source changes.
- Delete cleans all provider-owned Docker images.

## Phase 7: Provider 6 - Multi-Agent Intelligent Warehouse

Estimated time: 4-8 hours.

Provider source repo: `https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia`

Steps:

1. Clone/install source fresh.
2. Inspect compose project/image/container naming and cleanup paths.
3. Fix source cleanup if source owns compose lifecycle; otherwise harden Hub wrapper.
4. Source-level validation:
   - Compose config with `deploy/compose/.env`.
   - Run dev compose.
   - Health `8091`, UI `13002`, nginx `13003` if applicable.
5. Real function validation:
   - Submit a real warehouse assistant query through API/UI.
   - Confirm generated answer uses NVIDIA API/RAG path, not fallback.
   - Validate at least one dashboard/API data operation that proves backend services are working.
6. Commit/push provider source if changed.
7. Fresh Hub install/run after push.
8. Hub delete and resource cleanup verification.

Pass criteria:

- Warehouse assistant returns real generated result.
- Backend and UI are functional.
- Delete removes all Warehouse Docker resources.

## Phase 8: Provider 7 - PDF to Podcast

Estimated time: 5-10 hours because real output generation may be slow and requires TTS credentials.

Provider source repo: `https://github.com/PhuongHo03/pdf-to-podcast.git`

Steps:

1. Clone/install source fresh.
2. Inspect compose project/image/container naming and cleanup scripts.
3. Fix source cleanup if needed:
   - Ensure provider-owned images are removable.
   - Ensure large worker images are not left behind after delete.
   - Ensure volumes and object storage data are removed.
4. Source-level validation:
   - Compose config.
   - Run stack.
   - Health Gradio `7860` and API `8002`.
5. Real function validation:
   - Use a small test PDF that contains non-sensitive sample text.
   - Submit real PDF-to-podcast job.
   - Confirm script generation uses real NVIDIA API.
   - Confirm TTS/audio generation uses real configured TTS API if key is available.
   - Confirm downloadable/generated audio output exists and is non-empty.
6. If TTS key is missing:
   - Do not mark provider 100% pass.
   - Stop and ask user for the required key or mark blocked with exact missing key name only.
7. Commit/push provider source if changed.
8. Fresh Hub install/run after push.
9. Hub delete and image cleanup verification.

Pass criteria:

- Real PDF input produces real podcast/audio output.
- Delete removes all PDF-to-Podcast Docker resources and large images.

## Phase 9: Cross-Provider Fresh Clone Matrix

Estimated time: 2-4 hours after individual provider phases.

Steps:

1. Start Hub backend and frontend.
2. For each provider in order:
   - Ensure no existing deploy directory.
   - Install through Hub.
   - Run through Hub.
   - Health and metrics from Hub API.
   - Real function smoke check.
   - Stop if available.
   - Delete through Hub.
   - Docker cleanup verification.
3. Record per-provider result table:
   - Source commit pushed.
   - Hub commit used.
   - Fresh clone commit hash.
   - Real function result summary.
   - Delete cleanup result summary.
   - Remaining resources, if any.
4. Verify Hub frontend/backend processes survive every provider install/delete.

Testing gate:

- All seven providers pass with no fallback-only results.
- No provider-owned Docker resources remain after the final delete.
- Hub remains stable.

## Phase 10: CI, Docs, Logs, and Push

Estimated time: 1.5-3 hours.

Steps:

1. Run backend tests relevant to provider runtime and cleanup.
2. Run provider manifest validation.
3. Run frontend typecheck/tests if Hub UI or provider data changed.
4. Run security checks for secrets and accidental deploy artifacts.
5. Update docs under `docs/` if user-facing lifecycle behavior changes.
6. Update task log under `logs/tasks/` with concise phase results, no secrets.
7. Commit Hub changes with clear timestamped description.
8. Push Hub repo.
9. Check CI if `gh` is available; otherwise report that CI monitoring requires GitHub CLI/browser.

Testing gate:

- Local tests pass.
- Secret scan passes.
- Hub repo pushed.
- Provider repo pushes completed for every source change.

## Provider Validation Commands Checklist

Exact commands may be adjusted after reading each provider source, but each phase must include equivalents of:

- `git status --short`
- `git remote -v`
- `git rev-parse HEAD`
- `docker compose config --quiet` for compose providers.
- Hub install endpoint or UI action.
- Hub run endpoint or UI action.
- Provider health URL check.
- Provider real function API/UI call.
- Hub delete endpoint or UI action.
- Docker resource checks using provider-specific filters:
  - containers by compose project/name prefix.
  - images by compose labels/name prefix.
  - volumes by compose project/name prefix.
  - networks by compose project/name prefix.

## Blockers That Must Stop the Run

- Missing required real API key for a provider function test.
- Provider source repo push permission denied after source changes.
- Docker daemon unavailable.
- Real function returns fallback/static/mocked response only.
- Delete removes Hub frontend/backend or unrelated processes.
- Cleanup would delete resources outside provider ownership.
- Secret appears in diff, logs, or staged files.

## Initial Execution Order

1. Phase 0 preflight.
2. Phase 1 Hub cleanup contract.
3. Provider phases in this order to minimize risk and reuse learnings:
   - Shop Retail, because source push already exists and real chat validation is known.
   - Nemotron Voice Agent, because it uses shared dispatch and Docker Compose.
   - AI Virtual Assistant, because it uses shared dispatch/overrides.
   - Agentic Commerce Blueprint.
   - Warehouse.
   - AI-Q.
   - PDF-to-Podcast last because full real audio generation depends on extra TTS credentials and may be slow.
4. Phase 9 full matrix.
5. Phase 10 docs/logs/push.

## Expected Deliverables

- Provider repo commits for any provider source changes.
- Hub repo commit for wrapper/tests/docs/logs.
- `logs/tasks/seven-provider-delete-image-cleanup-real-validation-2026-05-19.log.md`.
- Optional docs update under `docs/` if lifecycle/delete behavior changes for users.
- Final result table showing 7/7 pass or exact blocker with missing requirement.
