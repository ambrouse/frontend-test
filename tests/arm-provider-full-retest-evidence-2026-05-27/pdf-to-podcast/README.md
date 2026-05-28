# PDF to Podcast

Status: partial pass on ARM.

Fresh source after provider push: `deploy/pdf-to-podcast` cloned from `https://github.com/PhuongHo03/pdf-to-podcast.git` at `bbea1b0`.

Source fix pushed:
- `bbea1b0 fix: widen AI Hub port allocation on Linux 2026-05-27`
- Fix expands the provider port scan beyond the previous `6050` ceiling and handles inherited start ports above the ceiling.

Result:
- Hub install: pass.
- Hub run: pass after provider source fix, delete, fresh install, and rerun.
- Runtime: frontend ready on `http://localhost:7860`; API health ready on `http://localhost:8002/health`.
- Upload: pass with provider sample PDF.
- PDF processing: pass; output shows `All PDFs processed successfully`.
- Full podcast generation: blocked at agent stage; output shows `Failed to get response after 5 attempts`, consistent with missing hosted LLM/TTS credentials on this host.

Evidence:
- `lifecycle/01-hub-running-status.png`
- `logs/01-hub-service-logs-streaming.png`
- `logs/02-hub-detailed-logs-streaming.png`
- `app/01-provider-ui-ready.png`
- `function/01-pdf-upload-ready.png`
- `function/02-pdf-processing-then-agent-key-blocker.png`
