# AIQ

Status: pass for current existing-key scope.

The provider was installed and run through Hub after the post-push cleanup. The frontend opened, data sources loaded, `README.md` was uploaded/attached, and a file-grounded question returned an answer citing the uploaded README.

## Evidence

| Area | Screenshot | Proof |
| --- | --- | --- |
| Lifecycle | [Hub running status](lifecycle/01-hub-running-status.png) | Hub shows AIQ running after real install/run |
| Logs | [Service logs streaming](logs/01-hub-service-logs-streaming.png) | Hub service log panel shows AIQ runtime output |
| App | [AIQ home ready](app/01-aiq-home-ready.png) | AIQ frontend is open and ready |
| Function | [Data sources panel](function/01-data-sources-panel.png) | Data-source UI opens from the frontend |
| Function | [README upload completed](function/02-file-upload-readme-completed.png) | File upload completed and appeared as available |
| Function | [Composer README attached](function/03-composer-readme-attached.png) | Uploaded file was attached to the chat composer |
| Function | [File-grounded answer](function/04-file-grounded-chat-answer.png) | Chat returned a grounded answer with `README.md` citation |

## Key Scope

`TAVILY_API_KEY` and `SERPER_API_KEY` were not available in the existing environment, so external web/paper search was not counted as pass evidence. The accepted frontend proof is the file-upload plus file-grounded chat flow, which produced a visible answer.

## Fix Loop

No new provider source change was needed in this post-push run. The prior AIQ blocker is resolved for the accepted current scope.

