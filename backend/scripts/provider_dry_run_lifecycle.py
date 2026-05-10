from __future__ import annotations

import os
import shutil
import sys
import time

from fastapi.testclient import TestClient

from app.core.paths import deploy_root
from app.main import app

PROVIDERS = ("agentic-commerce-blueprint", "multi-agent-intelligent-warehouse")


def wait_task(client: TestClient, task_id: str, timeout: float = 60) -> dict:
    deadline = time.perf_counter() + timeout
    while time.perf_counter() < deadline:
        task = client.get(f"/api/tasks/{task_id}").json()
        if task.get("status") in {"completed", "failed"}:
            return task
        time.sleep(0.1)
    raise TimeoutError(f"Task {task_id} timed out")


def run_action(client: TestClient, provider_id: str, action: str) -> None:
    if action == "delete":
        response = client.request("DELETE", f"/api/providers/{provider_id}", json={"force": True, "dryRun": True})
    else:
        response = client.post(f"/api/providers/{provider_id}/{action}", json={"force": True, "dryRun": True})
    response.raise_for_status()
    task = wait_task(client, response.json()["taskId"])
    if task["status"] != "completed":
        raise RuntimeError(f"{provider_id} {action} failed: {task}")


def cleanup_deploy(provider_id: str) -> None:
    target = (deploy_root() / provider_id).resolve()
    base = deploy_root().resolve()
    if target.exists() and (base == target or base in target.parents):
        shutil.rmtree(target, onerror=_handle_remove_readonly)


def _handle_remove_readonly(function, path, _exc_info) -> None:
    os.chmod(path, 0o700)
    function(path)


def main() -> int:
    os.environ["AIHUB_DRY_RUN"] = "1"
    client = TestClient(app)
    for provider_id in PROVIDERS:
        cleanup_deploy(provider_id)
        for action in ("install", "run", "stop", "delete"):
            run_action(client, provider_id, action)
        if (deploy_root() / provider_id).exists():
            print(f"{provider_id}: deploy directory still exists after delete", file=sys.stderr)
            return 1
    print(f"Dry-run lifecycle passed for {len(PROVIDERS)} providers")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
