from __future__ import annotations

from pathlib import Path
from time import sleep

from fastapi.testclient import TestClient

from app.core.paths import repo_root
from app.main import app
from app.schemas.models import ProviderConfig
from app.services.provider_runtime import _apply_config_env

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
    local_config = repo_root() / "providers/agentic-commerce-blueprint/runtime/config.local.json"
    local_config.unlink(missing_ok=True)
    response = client.patch("/api/providers/agentic-commerce-blueprint/config", json={"port": 1})
    assert response.status_code == 200
    config = response.json()
    assert config["port"] == 1
    assert local_config.exists()
    client.patch("/api/providers/agentic-commerce-blueprint/config", json={"port": 8088})
    local_config.unlink(missing_ok=True)


def test_reserved_hub_frontend_port_blocks_lifecycle_script() -> None:
    local_config = repo_root() / "providers/agentic-commerce-blueprint/runtime/config.local.json"
    local_config.unlink(missing_ok=True)
    client.patch("/api/providers/agentic-commerce-blueprint/config", json={"port": 3000})

    install = client.post("/api/providers/agentic-commerce-blueprint/install", json={"dryRun": False})
    assert install.status_code == 200
    task = _wait_task(install.json()["taskId"])

    assert task["status"] == "failed"
    assert "reserved for the Hub frontend dev server" in task["currentStep"]
    client.patch("/api/providers/agentic-commerce-blueprint/config", json={"port": 8088})
    local_config.unlink(missing_ok=True)


def test_provider_config_persists_local_env_without_touching_defaults() -> None:
    local_config = repo_root() / "providers/pdf-to-podcast/runtime/config.local.json"
    local_config.unlink(missing_ok=True)
    default_config_path = repo_root() / "providers/pdf-to-podcast/config/default.json"
    default_config = default_config_path.read_text(encoding="utf-8")

    response = client.patch(
        "/api/providers/pdf-to-podcast/config",
        json={"env": {"NVIDIA_API_KEY": "test-key", "API_SERVICE_PORT": "8012"}},
    )

    assert response.status_code == 200
    config = response.json()
    assert config["env"]["NVIDIA_API_KEY"] == "test-key"
    assert config["env"]["API_SERVICE_PORT"] == "8012"
    assert default_config_path.read_text(encoding="utf-8") == default_config
    local_config.unlink(missing_ok=True)


def test_empty_provider_env_does_not_clear_process_secret() -> None:
    env = {"NVIDIA_API_KEY": "existing-secret", "NGC_API_KEY": "existing-ngc"}
    config = ProviderConfig(
        profile="default",
        branch="main",
        port=8088,
        installDirectory="deploy/provider",
        env={"NVIDIA_API_KEY": "", "NGC_API_KEY": "", "MERCHANT_API_KEY": "merchant-test"},
    )

    _apply_config_env(env, config)

    assert env["NVIDIA_API_KEY"] == "existing-secret"
    assert env["NGC_API_KEY"] == "existing-ngc"
    assert env["MERCHANT_API_KEY"] == "merchant-test"


def test_provider_service_log_sources_include_web_agent_process_files() -> None:
    response = client.get("/api/providers/web-agent/service-logs/sources")

    assert response.status_code == 200
    data = response.json()
    assert data["mode"] == "process_files"
    source_ids = {source["id"] for source in data["sources"]}
    assert {"backend", "frontend", "backend-err", "frontend-err"}.issubset(source_ids)


def test_provider_service_logs_tail_and_clear_whitelisted_file() -> None:
    log_path = repo_root() / "deploy/web-agent/logs/backend.dev.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text("server ready\nERROR failed request\n", encoding="utf-8")

    response = client.get("/api/providers/web-agent/service-logs", params={"source": "backend", "level": "error"})
    assert response.status_code == 200
    logs = response.json()["logs"]
    assert len(logs) == 1
    assert logs[0]["level"] == "error"
    assert "failed request" in logs[0]["message"]

    clear = client.delete("/api/providers/web-agent/service-logs", params={"source": "backend"})
    assert clear.status_code == 200
    assert clear.json()["mode"] == "files"
    assert log_path.read_text(encoding="utf-8") == ""
    log_path.unlink(missing_ok=True)


def test_active_provider_delete_scripts_remove_images() -> None:
    providers_root = repo_root() / "providers"
    provider_ids = {
        "agentic-commerce-blueprint",
        "ai-virtual-assistant-provider",
        "aiq",
        "nemotron-voice-agent-provider",
        "shop-retail-provider",
        "multi-agent-intelligent-warehouse",
        "pdf-to-podcast",
        "web-agent",
    }
    delete_scripts: list[Path] = []
    for provider_id in provider_ids:
        provider_dir = providers_root / provider_id
        delete_scripts.extend(provider_dir.glob("scripts/windows/delete.ps1"))
        delete_scripts.extend(provider_dir.glob("scripts/linux/delete.sh"))
    delete_scripts.append(providers_root / "_shared/linux-provider-dispatch.sh")

    stale = [
        str(path.relative_to(repo_root()))
        for path in delete_scripts
        if "--rmi local" in path.read_text(encoding="utf-8")
    ]
    weak = []
    for path in delete_scripts:
        text = path.read_text(encoding="utf-8")
        if "docker compose" not in text:
            continue
        if (
            "--rmi all" not in text
            and "Invoke-DockerComposeCleanup" not in text
            and "linux-provider-dispatch.sh" not in text
        ):
            weak.append(str(path.relative_to(repo_root())))

    assert not stale
    assert not weak
