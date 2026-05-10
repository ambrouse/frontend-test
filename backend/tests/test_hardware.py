from __future__ import annotations

import subprocess
from types import SimpleNamespace

from app.services import hardware
from app.services.hardware import HardwareService


def test_nvidia_smi_parser(monkeypatch) -> None:
    def fake_run(*_args, **_kwargs):
        return subprocess.CompletedProcess(
            args=["nvidia-smi"],
            returncode=0,
            stdout="NVIDIA RTX 4090, 560.94, 46, 68, 24576, 11320\n",
            stderr="",
        )

    monkeypatch.setattr(hardware.subprocess, "run", fake_run)

    gpu = hardware._collect_nvidia_gpu()

    assert gpu["name"] == "NVIDIA RTX 4090"
    assert gpu["vendor"] == "NVIDIA"
    assert gpu["usagePercent"] == 46
    assert gpu["temperatureC"] == 68
    assert gpu["vramTotalMb"] == 24576
    assert gpu["vramUsedMb"] == 11320
    assert gpu["driverVersion"] == "560.94"


def test_nvidia_smi_missing_is_unknown(monkeypatch) -> None:
    def fake_run(*_args, **_kwargs):
        raise FileNotFoundError

    monkeypatch.setattr(hardware.subprocess, "run", fake_run)

    gpu = hardware._collect_nvidia_gpu()

    assert gpu["name"] == "No NVIDIA GPU detected"
    assert gpu["vendor"] == "unknown"
    assert gpu["vramTotalMb"] == 0


def test_snapshot_uses_real_psutil_values_without_seed_gpu(monkeypatch) -> None:
    fake_psutil = SimpleNamespace(
        virtual_memory=lambda: SimpleNamespace(total=32 * 1024 * 1024 * 1024, used=8 * 1024 * 1024 * 1024),
        disk_usage=lambda _path: SimpleNamespace(
            total=1000 * 1024 * 1024 * 1024,
            free=400 * 1024 * 1024 * 1024,
        ),
        cpu_count=lambda logical=True: 12,
        cpu_percent=lambda interval=None: 7.5,
        sensors_temperatures=lambda fahrenheit=False: {},
    )
    monkeypatch.setattr(hardware, "psutil", fake_psutil)
    monkeypatch.setattr(hardware, "_cpu_name", lambda: "Test CPU")

    snapshot = HardwareService(ttl_seconds=0.1).snapshot()

    assert snapshot.cpu.name == "Test CPU"
    assert snapshot.cpu.cores == 12
    assert snapshot.ram.totalMb == 32768
    assert snapshot.disk.installPathFreeGb == 400
    assert snapshot.gpu.name == "No NVIDIA GPU detected"
    assert snapshot.gpu.vramTotalMb == 0
