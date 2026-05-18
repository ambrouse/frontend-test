from __future__ import annotations

import json
import os
import platform
import re
import shutil
import socket
import subprocess
import time
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path

from app.core.paths import repo_root
from app.schemas.models import (
    HubProject,
    ProjectLog,
    ProviderActionRequest,
    ProviderActionResponse,
    ProviderConfig,
    ProviderLogsResponse,
    ProviderMetrics,
    ProviderStatus,
)
from app.services.provider_registry import provider_registry
from app.services.task_store import task_store


@dataclass
class ScriptResult:
    returncode: int
    stdout: str
    stderr: str = ""


CONFIG_KEYS = ("profile", "branch", "port", "installDirectory")
LOCAL_CONFIG_PATH = "runtime/config.local.json"
ENV_KEY_PATTERN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def provider_status(provider_id: str) -> ProviderStatus:
    provider = _require_provider(provider_id)
    data = _read_json(
        _provider_file(provider, provider.runtime.statusFile if provider.runtime else "runtime/status.json")
    )
    if data:
        return ProviderStatus.model_validate(data)
    return _default_status(provider)


def provider_metrics(provider_id: str) -> ProviderMetrics:
    provider = _require_provider(provider_id)
    metrics_path = _provider_file(
        provider,
        provider.runtime.metricsFile if provider.runtime else "runtime/metrics.json",
    )
    _refresh_metrics(provider, metrics_path)
    data = _read_json(metrics_path)
    if data:
        return ProviderMetrics.model_validate(data)
    return ProviderMetrics(
        sampledAt=datetime.now(UTC).isoformat(),
        platform=_platform_name(),
        process={"cpuPercent": 0, "ramMb": 0, "gpuPercent": 0, "vramMb": 0},
        service={"requestsTotal": 0, "requestsPerMin": 0, "latencyP50Ms": 0, "latencyP95Ms": 0, "errorsLastHour": 0},
        benchmark=provider.lastBenchmark.model_dump(),
    )


def provider_config(provider_id: str) -> ProviderConfig:
    provider = _require_provider(provider_id)
    base = provider.editableConfig.model_dump()
    base["env"] = {}
    for data in (
        _read_json(_provider_file(provider, "config/default.json")),
        _read_json(_provider_file(provider, LOCAL_CONFIG_PATH)),
    ):
        _merge_config_data(base, data)
    config = ProviderConfig(**base)
    if _is_port_in_use(config.port):
        config.warnings.append(f"Port {config.port} is already in use")
    return config


def patch_provider_config(provider_id: str, patch: dict) -> ProviderConfig:
    provider = _require_provider(provider_id)
    current = provider_config(provider_id).model_dump()
    for key in CONFIG_KEYS:
        if key in patch:
            current[key] = patch[key]
    if "env" in patch and isinstance(patch["env"], dict):
        current_env = dict(current.get("env", {}))
        for key, value in patch["env"].items():
            key = str(key).strip()
            if not ENV_KEY_PATTERN.match(key):
                continue
            current_env[key] = "" if value is None else str(value)
        current["env"] = current_env
    current["warnings"] = []
    config = ProviderConfig.model_validate(current)
    if _is_port_in_use(config.port):
        config.warnings.append(f"Port {config.port} is already in use")
    path = _provider_file(provider, LOCAL_CONFIG_PATH)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(
            {
                **{key: getattr(config, key) for key in CONFIG_KEYS},
                "env": config.env,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    provider_registry.refresh(force=True)
    return config


def provider_logs(
    provider_id: str, tail: int = 200, cursor: int | None = None, level: str | None = None
) -> ProviderLogsResponse:
    provider = _require_provider(provider_id)
    log_path = _provider_file(provider, provider.runtime.logFile if provider.runtime else "logs/runtime.log")
    if not log_path.exists():
        return ProviderLogsResponse(logs=[], cursor=0)

    file_size = log_path.stat().st_size
    start = cursor if cursor is not None else max(0, file_size - 256 * 1024)
    with log_path.open("rb") as log_file:
        log_file.seek(start)
        raw_lines = log_file.read().decode("utf-8", errors="replace").splitlines()
        next_cursor = log_file.tell()

    logs = [_parse_log_line(provider_id, index, line) for index, line in enumerate(raw_lines[-tail:])]
    if level and level != "all":
        logs = [log for log in logs if log.level == level]
    return ProviderLogsResponse(logs=logs, cursor=next_cursor)


def install_provider(provider_id: str, request: ProviderActionRequest) -> ProviderActionResponse:
    return _queue_action(provider_id, "setup", "installing", "Installing provider", request)


def run_provider(provider_id: str, request: ProviderActionRequest) -> ProviderActionResponse:
    config = provider_config(provider_id)
    warnings = list(config.warnings)
    if warnings and not request.force:
        task = task_store.create(
            project_id=provider_id,
            project_name=_require_provider(provider_id).name,
            project_type=_require_provider(provider_id).type,
            status="failed",
            current_step=warnings[0],
            progress_percent=100,
        )
        return ProviderActionResponse(taskId=task.id, status=task.status, warnings=warnings)
    response = _queue_action(provider_id, "run", "running", "Starting provider", request)
    response.warnings.extend(warnings)
    return response


def stop_provider(provider_id: str, request: ProviderActionRequest) -> ProviderActionResponse:
    return _queue_action(provider_id, "stop", "stopping", "Stopping provider", request)


def delete_provider(provider_id: str, request: ProviderActionRequest) -> ProviderActionResponse:
    return _queue_action(provider_id, "delete", "deleting", "Deleting provider deploy files", request)


def _queue_action(
    provider_id: str,
    command_name: str,
    status: str,
    current_step: str,
    request: ProviderActionRequest,
) -> ProviderActionResponse:
    provider = _require_provider(provider_id)
    existing_task = task_store.find_active_by_project(provider.id)
    if existing_task is not None:
        return ProviderActionResponse(
            taskId=existing_task.id,
            status=existing_task.status,
            warnings=[
                f"Provider already has active task {existing_task.id} ({existing_task.status}). Wait for it to finish."
            ],
        )
    task = task_store.create(
        project_id=provider.id,
        project_name=provider.name,
        project_type=provider.type,
        status=status,  # type: ignore[arg-type]
        current_step=current_step,
    )
    task_store.submit(task, lambda task_id: _run_action(task_id, provider, command_name, request))
    return ProviderActionResponse(taskId=task.id, status=task.status)


def _run_action(task_id: str, provider: HubProject, command_name: str, request: ProviderActionRequest) -> None:
    task_store.update(task_id, current_step=f"Running {command_name}", progress_percent=15)
    if command_name in {"setup", "delete"}:
        _clear_runtime_log(provider)
    _append_log(provider, "system", "info", f"{command_name} started")

    if request.dryRun or os.environ.get("AIHUB_DRY_RUN") == "1":
        _complete_dry_run_action(task_id, provider, command_name)
        return

    if command_name == "delete" and not _script_for(provider, command_name):
        _delete_deploy(provider)
        _write_status(provider, state="not_installed", current_step="Deleted", progress=100)
        task_store.update(task_id, status="completed", current_step="Deleted", progress_percent=100)
        provider_registry.refresh(force=True)
        return

    command = _script_for(provider, command_name)
    if command is None:
        raise RuntimeError(f"Provider {provider.id} does not define command {command_name}")

    is_real_run = command_name == "run" and not (request.dryRun or os.environ.get("AIHUB_DRY_RUN") == "1")
    if is_real_run and not _provider_install_path(provider).exists():
        setup_command = _script_for(provider, "setup")
        if setup_command is None:
            message = "Deploy directory is missing and setup command is not defined"
            _append_log(provider, "system", "error", message)
            _write_status(provider, state="failed", current_step=message, progress=100)
            task_store.update(task_id, status="failed", current_step=message, progress_percent=100)
            provider_registry.refresh(force=True)
            return
        _append_log(provider, "system", "info", "Deploy directory missing. Running setup before run.")
        task_store.update(task_id, current_step="Deploy missing. Running setup first", progress_percent=25)
        setup_result = _run_script(provider, setup_command, request, task_id=task_id, command_name="setup")
        if setup_result.returncode != 0:
            message = _tail_message(setup_result.stderr.strip() or setup_result.stdout.strip() or "setup failed")
            _append_log(provider, "system", "error", message)
            _write_status(provider, state="failed", current_step=message, progress=100)
            task_store.update(task_id, status="failed", current_step=message, progress_percent=100)
            provider_registry.refresh(force=True)
            return

    task_store.update(task_id, current_step=f"Executing {command_name} script", progress_percent=35)
    try:
        result = _run_script(provider, command, request, task_id=task_id, command_name=command_name)
    except Exception as exc:
        result = ScriptResult(returncode=1, stdout="", stderr=str(exc))
    if result.returncode != 0:
        message = _tail_message(result.stderr.strip() or result.stdout.strip() or f"{command_name} failed")
        _append_log(provider, "system", "error", message)
        _write_status(provider, state="failed", current_step=message, progress=100)
        task_store.update(task_id, status="failed", current_step=message, progress_percent=100)
        provider_registry.refresh(force=True)
        return

    state = {"setup": "installed", "run": "running", "stop": "stopped", "delete": "not_installed"}.get(
        command_name, "completed"
    )
    if not _script_wrote_state(provider, state):
        _write_status(provider, state=state, current_step=f"{command_name} completed", progress=100)
    if command_name == "run" and not (request.dryRun or os.environ.get("AIHUB_DRY_RUN") == "1"):
        metrics_result = _run_utility_script(provider, "metrics", timeout_seconds=45)
        if metrics_result and metrics_result.returncode != 0:
            _append_log(provider, "system", "warn", _tail_message(metrics_result.stdout or metrics_result.stderr))
    if command_name == "delete":
        _delete_deploy(provider)
    task_store.update(task_id, status="completed", current_step=f"{command_name} completed", progress_percent=100)
    provider_registry.refresh(force=True)


def _run_script(
    provider: HubProject,
    command: str,
    request: ProviderActionRequest,
    *,
    task_id: str,
    command_name: str,
) -> ScriptResult:
    provider_root = _provider_file(provider, ".")
    env = os.environ.copy()
    env["AIHUB_PROVIDER_ID"] = provider.id
    env["AIHUB_PROVIDER_ROOT"] = str(provider_root)
    config = provider_config(provider.id)
    install_path = _provider_install_path(provider, config)
    env["AIHUB_DEPLOY_ROOT"] = str(install_path.parent)
    env["AIHUB_INSTALL_DIRECTORY"] = str(install_path)
    env["AIHUB_PORT"] = str(config.port)
    env["AIHUB_BRANCH"] = config.branch
    _apply_config_env(env, config)
    if request.dryRun or os.environ.get("AIHUB_DRY_RUN") == "1":
        env["AIHUB_DRY_RUN"] = "1"

    if _platform_name() == "windows":
        executable = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", command]
    else:
        executable = ["bash", command]
    output: list[str] = []
    output_path = _provider_file(provider, f"logs/{command_name}-script-output.log")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    last_offset = 0

    def drain_output() -> None:
        nonlocal last_offset
        if not output_path.exists():
            return
        with output_path.open("rb") as output_file:
            output_file.seek(last_offset)
            chunk = output_file.read()
            last_offset = output_file.tell()
        if not chunk:
            return
        for raw_line in chunk.decode("utf-8", errors="replace").splitlines():
            line = raw_line.rstrip()
            if not line:
                continue
            output.append(line)
            _append_log(provider, _log_source(command_name), "info", line[-2000:])
            task_store.update(task_id, current_step=line[-160:], progress_percent=60)

    started_at = time.monotonic()
    with output_path.open("w", encoding="utf-8", errors="replace") as output_file:
        process = subprocess.Popen(
            executable,
            cwd=provider_root,
            env=env,
            stdout=output_file,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        while True:
            returncode = process.poll()
            output_file.flush()
            drain_output()
            if returncode is not None:
                break
            if time.monotonic() - started_at > 60 * 60:
                process.kill()
                return ScriptResult(returncode=124, stdout="\n".join(output), stderr=f"{command_name} timed out")
            time.sleep(0.5)
    drain_output()
    return ScriptResult(returncode=returncode, stdout="\n".join(output))


def _complete_dry_run_action(task_id: str, provider: HubProject, command_name: str) -> None:
    state = {"setup": "installed", "run": "running", "stop": "stopped", "delete": "not_installed"}.get(
        command_name, "completed"
    )
    if command_name in {"setup", "run"}:
        _provider_install_path(provider).mkdir(parents=True, exist_ok=True)
    if command_name == "delete":
        _delete_deploy(provider)
    _write_status(provider, state=state, current_step=f"{command_name} dry-run completed", progress=100)
    _append_log(provider, "system", "info", f"{command_name} dry-run completed")
    task_store.update(task_id, status="completed", current_step=f"{command_name} completed", progress_percent=100)
    provider_registry.refresh(force=True)


def _refresh_metrics(provider: HubProject, metrics_path: Path) -> None:
    command = _script_for(provider, "metrics")
    if command is None:
        return
    should_collect = not metrics_path.exists()
    if metrics_path.exists():
        should_collect = time.time() - metrics_path.stat().st_mtime > 10
    if not should_collect:
        return
    result = _run_utility_script(provider, "metrics", timeout_seconds=45)
    if result and result.returncode != 0:
        _append_log(provider, "system", "warn", _tail_message(result.stdout or result.stderr or "metrics failed"))


def _run_utility_script(provider: HubProject, command_name: str, *, timeout_seconds: int) -> ScriptResult | None:
    command = _script_for(provider, command_name)
    if command is None:
        return None
    provider_root = _provider_file(provider, ".")
    env = os.environ.copy()
    env["AIHUB_PROVIDER_ID"] = provider.id
    env["AIHUB_PROVIDER_ROOT"] = str(provider_root)
    config = provider_config(provider.id)
    install_path = _provider_install_path(provider, config)
    env["AIHUB_DEPLOY_ROOT"] = str(install_path.parent)
    env["AIHUB_INSTALL_DIRECTORY"] = str(install_path)
    env["AIHUB_PORT"] = str(config.port)
    env["AIHUB_BRANCH"] = config.branch
    _apply_config_env(env, config)

    executable = (
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", command]
        if _platform_name() == "windows"
        else ["bash", command]
    )
    try:
        completed = subprocess.run(
            executable,
            cwd=provider_root,
            env=env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout_seconds,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return ScriptResult(returncode=124, stdout="", stderr=str(exc))
    return ScriptResult(returncode=completed.returncode, stdout=completed.stdout, stderr=completed.stderr)


def _script_wrote_state(provider: HubProject, expected_state: str) -> bool:
    status_path = _provider_file(provider, provider.runtime.statusFile if provider.runtime else "runtime/status.json")
    status = _read_json(status_path)
    return bool(status and status.get("state") == expected_state)


def _script_for(provider: HubProject, command_name: str) -> str | None:
    commands = provider.commands
    if commands is None:
        return None
    command_set = commands.windows if _platform_name() == "windows" else commands.linux
    return command_set.get(command_name)


def _merge_config_data(base: dict, data: dict | None) -> None:
    if not data:
        return
    for key in CONFIG_KEYS:
        if key in data:
            base[key] = data[key]
    env_data = data.get("env")
    if isinstance(env_data, dict):
        env = dict(base.get("env", {}))
        for key, value in env_data.items():
            key = str(key).strip()
            if ENV_KEY_PATTERN.match(key):
                env[key] = "" if value is None else str(value)
        base["env"] = env


def _apply_config_env(env: dict[str, str], config: ProviderConfig) -> None:
    for key, value in config.env.items():
        key = key.strip()
        if ENV_KEY_PATTERN.match(key):
            env[key] = value


def _log_source(command_name: str) -> str:
    return {"setup": "install", "run": "runtime", "stop": "system", "delete": "system"}.get(command_name, "system")


def _tail_message(message: str, *, max_chars: int = 240) -> str:
    lines = [line.strip() for line in message.splitlines() if line.strip()]
    if not lines:
        return message[:max_chars] or "Provider command failed"
    tail = "\n".join(lines[-8:])
    return tail[-max_chars:]


def _require_provider(provider_id: str) -> HubProject:
    provider = provider_registry.get_provider(provider_id)
    if provider is None:
        raise KeyError(provider_id)
    return provider


def _provider_file(provider: HubProject, relative_path: str) -> Path:
    return provider_registry.provider_root(provider.id) / relative_path


def _provider_install_path(provider: HubProject, config: ProviderConfig | None = None) -> Path:
    config = config or provider_config(provider.id)
    configured_path = Path(config.installDirectory)
    if not configured_path.is_absolute():
        configured_path = repo_root() / configured_path
    return configured_path.resolve()


def _read_json(path: Path) -> dict | None:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def _default_status(provider: HubProject) -> ProviderStatus:
    config = provider_config(provider.id)
    state = "installed" if _provider_install_path(provider, config).exists() else "not_installed"
    return ProviderStatus(
        projectId=provider.id,
        state=state,
        port=config.port,
        platform=_platform_name(),
        currentStep="Ready",
        progressPercent=100 if state == "installed" else 0,
        health={"level": "unknown", "message": "No runtime status yet"},
    )


def _write_status(provider: HubProject, *, state: str, current_step: str, progress: int) -> None:
    config = provider_config(provider.id)
    status = ProviderStatus(
        projectId=provider.id,
        state=state,
        port=config.port,
        platform=_platform_name(),
        currentStep=current_step,
        progressPercent=progress,
        health={
            "level": "ok" if state in {"installed", "running", "stopped", "not_installed"} else "error",
            "message": current_step,
        },
    )
    path = _provider_file(provider, provider.runtime.statusFile if provider.runtime else "runtime/status.json")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(status.model_dump_json(indent=2), encoding="utf-8")


def _clear_runtime_log(provider: HubProject) -> None:
    path = _provider_file(provider, provider.runtime.logFile if provider.runtime else "logs/runtime.log")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("", encoding="utf-8")


def _append_log(provider: HubProject, source: str, level: str, message: str) -> None:
    path = _provider_file(provider, provider.runtime.logFile if provider.runtime else "logs/runtime.log")
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "source": source,
        "level": level,
        "timestamp": datetime.now(UTC).isoformat(),
        "message": message,
    }
    with path.open("a", encoding="utf-8") as log_file:
        log_file.write(json.dumps(payload, ensure_ascii=True) + "\n")


def _parse_log_line(provider_id: str, index: int, line: str) -> ProjectLog:
    try:
        payload = json.loads(line)
    except json.JSONDecodeError:
        payload = {"source": "runtime", "level": "info", "message": line}
    return ProjectLog(
        id=f"{provider_id}-log-{index}",
        projectId=provider_id,
        source=payload.get("source", "runtime"),
        level=payload.get("level", "info"),
        timestamp=payload.get("timestamp", datetime.now(UTC).isoformat()),
        message=payload.get("message", ""),
    )


def _delete_deploy(provider: HubProject) -> None:
    deploy_path = _provider_install_path(provider)
    repo_base = repo_root().resolve()
    if repo_base not in deploy_path.parents:
        raise RuntimeError("Refusing to delete outside repository root")
    if deploy_path.exists():
        shutil.rmtree(deploy_path, onerror=_handle_remove_readonly)


def _handle_remove_readonly(function, path, _exc_info) -> None:
    os.chmod(path, 0o700)
    function(path)


def _is_port_in_use(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(0.05)
        return sock.connect_ex(("127.0.0.1", port)) == 0


def _platform_name() -> str:
    return "windows" if platform.system().lower().startswith("win") else "linux"
