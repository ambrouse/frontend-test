from __future__ import annotations

from time import sleep

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def _wait_task(task_id: str) -> dict:
    for _ in range(40):
        response = client.get(f"/api/tasks/{task_id}")
        response.raise_for_status()
        task = response.json()
        if task["status"] in {"completed", "failed"}:
            return task
        sleep(0.05)
    raise AssertionError(f"task {task_id} did not finish")


def test_provider_dry_run_lifecycle() -> None:
    install = client.post("/api/providers/agentic-commerce-blueprint/install", json={"dryRun": True})
    assert install.status_code == 200
    task = _wait_task(install.json()["taskId"])
    assert task["status"] == "completed"

    status = client.get("/api/providers/agentic-commerce-blueprint/status")
    assert status.status_code == 200
    assert status.json()["state"] == "installed"

    run = client.post("/api/providers/agentic-commerce-blueprint/run", json={"dryRun": True, "force": True})
    assert run.status_code == 200
    assert _wait_task(run.json()["taskId"])["status"] == "completed"
    assert client.get("/api/providers/agentic-commerce-blueprint/status").json()["state"] == "running"

    logs = client.get("/api/providers/agentic-commerce-blueprint/logs")
    assert logs.status_code == 200
    assert "logs" in logs.json()

    delete = client.request("DELETE", "/api/providers/agentic-commerce-blueprint", json={"dryRun": True})
    assert delete.status_code == 200
    assert _wait_task(delete.json()["taskId"])["status"] == "completed"
    assert client.get("/api/providers/agentic-commerce-blueprint/status").json()["state"] == "not_installed"


def test_provider_config_reports_port_conflict() -> None:
    response = client.patch("/api/providers/agentic-commerce-blueprint/config", json={"port": 1})
    assert response.status_code == 200
    config = response.json()
    assert config["port"] == 1
    client.patch("/api/providers/agentic-commerce-blueprint/config", json={"port": 8088})
