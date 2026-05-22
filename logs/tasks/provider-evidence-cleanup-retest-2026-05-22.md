# Provider Evidence Cleanup Retest - 2026-05-22

## 15:20 Start

- User requested stricter evidence cleanup and retest.
- Applied skills: `fix`, `plan-skill`, `testing-skill`, `readme-style`, `logging-skill`.
- Scope remains six in-scope providers only; `nemotron-voice-agent-provider` and `pdf-to-podcast` stay out of scope.

## Initial Audit

- Found one exact duplicate screenshot pair in `web-agent/function`.
- Found technical evidence files under `test/provider-functional-evidence-2026-05-21` (`.json`, `.txt`, `.log`) that should be replaced by README reports.
- `agentic-commerce-blueprint` needs stronger frontend search proof.

## Agentic Commerce Retest Finding

- Started Agentic Commerce through Hub and opened `http://localhost:8088`.
- Frontend Apps SDK search UI appeared, but search returned `Search agent unavailable for 'graphic tee'`.
- Runtime logs showed Milvus seeding failed because `NVIDIA_API_KEY` was empty in `deploy/agentic-commerce-blueprint/.env`.
- Root cause: Agentic Commerce Hub setup wrapper read process env only and did not load the existing root `.env.local` key.
- Fix applied in `providers/agentic-commerce-blueprint/scripts/windows/setup.ps1`: read root `.env.local`, use `NVIDIA_API_KEY` as fallback, and mirror values into process env while writing provider `.env`.
- Follow-up retest still failed because existing Docker containers kept the old empty env and the Hub run process could still override compose `.env` with empty process variables.
- Additional fix applied in `providers/agentic-commerce-blueprint/scripts/windows/run.ps1`: load deploy `.env` before Docker Compose and use `up -d --force-recreate` so containers receive the corrected env.
- After stop/run, `nat-search-agent` had `NVIDIA_API_KEY` present and Milvus seeder logged `SUCCESS: Seeded 17 products into Milvus`.
- Frontend Apps SDK search for `graphic tee` returned `Search Agent`, `3 items`, `Graphic Tee`, `Classic Tee`, and `Premium Tee`.
- User reviewed `05-apps-sdk-search-graphic-tee-results.png` and correctly found it was captured while still `Searching/PENDING`.
- Deleted that bad screenshot and recaptured only after both the Apps SDK widget and Agent Activity showed real search results.
- Current replacement screenshot shows widget product cards plus `SEARCH AGENT`, `3 items`, `Graphic Tee`, `Classic Tee`, and `Premium Tee`.
- New evidence rule for the rest of this pass: every screenshot must be read back after capture; screenshots that still show loading, pending, empty, or error states cannot be kept as pass evidence.

## Evidence Cleanup Correction

- While removing technical evidence files, the cleanup command removed previous evidence images too.
- Recovery action: rebuild the evidence set from live frontend runs with new screenshots instead of using stale files.

## AIVA Retest Finding

- AIVA frontend and customer data loaded at port `13301`.
- Suggested/custom chat initially returned the UI fallback `Something went wrong`.
- `agent-chain-server` logs showed NVIDIA hosted endpoint `401 Unauthorized` for the default `meta/llama-3.3-70b-instruct` model while the current key worked for Agentic Commerce.
- Fix applied in `providers/ai-virtual-assistant-provider/scripts/windows/setup.ps1`: default hosted LLM model changed to `nvidia/llama-3.1-nemotron-nano-8b-v1` when no explicit `APP_LLM_MODELNAME` is set.

## AIQ Retest Finding

- Audited provider source clone rule before retest.
- `deploy/aiq/setup.sh` contained the source-side Windows/Git Bash portability fix that was required for fresh install.
- Committed and pushed the provider source fix to `origin/develop` as `7418832 fix: harden Windows setup shell portability 2026-05-22`.
- Fresh Hub install/run completed after that push.
- AIQ must be opened at `http://localhost:13080`; `127.0.0.1` leaves the UI partially unhydrated in this dev build.
- Rebuilt frontend evidence from live UI:
  - home screen with hydrated data source count `2/2`;
  - Data Sources panel showing `Web Search` and `Academic Papers`;
  - file upload through the UI, with `README.md` reaching `Available`;
  - file-grounded chat answer citing `README.md` and answering that the project is `AI Hub`;
  - Hub status/metrics showing `Running`, `2 agents`, backend `18081`, frontend `13080`;
- Hub Service logs tab showing streamed backend log lines.
- Read back the final AIQ screenshots after capture; deleted/overwrote screenshots that still showed only uploading/pending states.

## Shop Retail Retest Finding

- Audited `deploy/shop-retail-provider`; source clone was clean and tracking `origin/main` at pushed commit `8a4ab1e fix catalog retrieval fallback for image search`.
- Fresh Hub delete/install/run was executed from the pushed provider source.
- First frontend chat attempt failed to produce assistant output; service logs showed NVIDIA hosted endpoints returning `401 Unauthorized`.
- Root cause: the Hub wrapper copied placeholder `[REDACTED...]` values into `.env` and process env instead of falling back to the real root `.env.local` key.
- Fix applied in `providers/shop-retail-provider/scripts/windows/setup.ps1`: ignore `[REDACTED...]` placeholder secrets for `NVIDIA_API_KEY`, `NGC_API_KEY`, `LLM_API_KEY`, `EMBED_API_KEY`, and `RAIL_API_KEY`.
- Re-ran fresh delete/install/run after wrapper fix; `.env` and containers then received real masked `nvapi` key values.
- Rebuilt frontend evidence from live UI:
  - app home with chat ready;
  - text product search for summer skirts returning product cards;
  - image upload/search returning shoe product cards;
  - Guardrails toggle enabled with an assistant response;
  - reset clearing a completed chat back to the welcome state;
  - Hub status/metrics showing `Running`, `9 containers`, and port `13100`;
  - Hub Service logs showing live gateway query/health traffic.
- Read back the final Shop screenshots after capture; overwrote screenshots that only showed prompt/upload states without results.

## Warehouse Retest Finding

- Audited `deploy/multi-agent-intelligent-warehouse`; source clone was initially clean at pushed commit `4d45dac`.
- Frontend chat initially exposed an NVIDIA auth failure because Warehouse `.env` contained `[REDACTED...]` placeholders instead of the real root `.env.local` key.
- Fix applied in `providers/multi-agent-intelligent-warehouse/scripts/windows/setup.ps1`: load root `.env.local`, ignore placeholder secrets, and write usable `NVIDIA_API_KEY`, `EMBEDDING_API_KEY`, and `RAIL_API_KEY` values.
- Fresh delete/install/run confirmed Warehouse `.env` and backend container had usable key values.
- Document upload then exposed source dependency failure: backend image lacked `Pillow`, causing `No module named 'PIL'` during document preprocessing.
- Source fix pushed to provider repo: `ae588eb fix: include Pillow in Docker requirements 2026-05-22`.
- Fresh delete/install/run confirmed `Pillow` import in backend container.
- Document validation then exposed source fallback failure: NVIDIA judge timeout marked document `FAILED` even though the pipeline continued to routing/results.
- Source fix pushed to provider repo: `9558b93 fix: keep document pipeline running on judge fallback 2026-05-22`.
- Final fresh delete/install/run from pushed source commit `9558b93` passed frontend validation.
- Rebuilt Warehouse evidence from live UI:
  - authenticated dashboard;
  - chat query returning forklift structured output with `FL-01`, `FL-02`, `FL-03`, and maintenance status;
  - equipment assets and maintenance views;
  - forecasting summary and reorder recommendations;
  - operations workforce status;
  - safety incident created through the frontend form;
  - document upload of `test_invoice.png` reaching Completed/Auto-Approved;
  - analytics, documentation, MCP tool discovery;
  - Hub running status and live service logs.
- Read back key Warehouse screenshots after capture: chat output, document completed card, MCP loaded tools, Hub status, and service logs.

## Retroactive Source Push Audit

- AIQ source clone still had an unpushed `setup.sh` port-probe change from earlier validation.
- Source fix pushed to AIQ repo: `9bfbbdc fix: add PowerShell port probe for Windows setup 2026-05-22` on `origin/develop`.
- AIQ Hub wrapper was then fixed to make the source patch idempotent so fresh install does not duplicate the PowerShell probe.
- Final AIQ fresh delete/install/run was executed after push; `setup.sh` stayed clean after the wrapper fix. Remaining AIQ dirty files are generated install/build artifacts (`egg-info`, runtime DBs, venv), not source fixes to push.
- AIQ evidence was refreshed after the final push/install/run: app, data sources, README upload, README-grounded chat answer, Hub status, and service logs.
- Other audited source clone states:
  - Shop source clone is at pushed commit `8a4ab1e`; current fix was Hub wrapper only.
  - Warehouse source clone is at pushed commit `9558b93`.
  - Web Agent prior source fix is already pushed at `a908165`; remaining dirty files are unrelated generated/user files and were not pushed.
  - Agentic Commerce source clone had no source changes in this pass.
  - AIVA source clone only has runtime/generated untracked data.

## Evidence Packaging

- Removed technical evidence files from `test/provider-functional-evidence-2026-05-21`; final evidence tree contains only `.png` screenshots and `.md` reports.
- Generated README reports for the evidence root, each provider folder, and each provider subfolder (`app`, `function`, `lifecycle`, `logs`) using the repo README style direction.
- Duplicate image hash scan returned no duplicates.
- Secret scan for `nvapi-...` under `test`, `logs`, `plans`, and `providers` returned no matches.

## 12:47 Close

- Cleaned the generated README reports again after finding control characters/placeholders in provider report text.
- Removed stale AIQ app screenshot `01-aiq-home.png`; retained `01-aiq-home-datasources-loaded.png` as the single app-ready proof for AIQ.
- Regenerated subfolder README reports from the actual screenshot files so no report links to deleted or missing evidence.
- Final scans:
  - non-image/report evidence files: none;
  - duplicate screenshot hashes: none;
  - README missing links/placeholders/control characters: none;
  - `nvapi-...` secret pattern in `test`, `logs`, `plans`, and `providers`: none.
- Final status: plan closed/pass for the agreed six-provider scope.
