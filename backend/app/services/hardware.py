from __future__ import annotations

import os
import platform
import subprocess
from datetime import UTC, datetime
from threading import Lock, Thread
from time import monotonic

from app.core.paths import deploy_root
from app.schemas.models import HardwareSnapshot

try:
    import psutil
except ImportError:  # pragma: no cover
    psutil = None


class HardwareService:
    def __init__(self, ttl_seconds: float = 1.0, gpu_ttl_seconds: float = 5.0) -> None:
        self._ttl_seconds = ttl_seconds
        self._gpu_ttl_seconds = gpu_ttl_seconds
        self._lock = Lock()
        self._gpu_lock = Lock()
        self._gpu_refreshing = False
        self._gpu_updated_at = 0.0
        self._gpu_snapshot = _unknown_gpu()
        self._snapshot = HardwareSnapshot.model_validate(_unknown_snapshot())
        self._updated_at = 0.0

    def snapshot(self) -> HardwareSnapshot:
        now = monotonic()
        if now - self._updated_at < self._ttl_seconds:
            return self._snapshot

        with self._lock:
            if now - self._updated_at >= self._ttl_seconds:
                self._snapshot = self._collect_fast_snapshot()
                self._updated_at = now
        self._refresh_gpu_if_stale()
        return self._snapshot

    def _collect_fast_snapshot(self) -> HardwareSnapshot:
        if psutil is None:
            data = _unknown_snapshot()
            data["timestamp"] = _utc_now()
            return HardwareSnapshot.model_validate(data)

        virtual_memory = psutil.virtual_memory()
        disk_usage = psutil.disk_usage(str(deploy_root()))
        data = {
            "cpu": {
                "name": _cpu_name(),
                "cores": psutil.cpu_count(logical=True) or 0,
                "usagePercent": round(float(psutil.cpu_percent(interval=None)), 2),
                "temperatureC": _cpu_temperature(),
            },
            "gpu": self._gpu_snapshot,
            "ram": {
                "totalMb": int(virtual_memory.total / 1024 / 1024),
                "usedMb": int(virtual_memory.used / 1024 / 1024),
            },
            "disk": {
                "totalGb": int(disk_usage.total / 1024 / 1024 / 1024),
                "freeGb": int(disk_usage.free / 1024 / 1024 / 1024),
                "installPathFreeGb": int(disk_usage.free / 1024 / 1024 / 1024),
            },
            "timestamp": _utc_now(),
        }
        return HardwareSnapshot.model_validate(data)

    def _refresh_gpu_if_stale(self) -> None:
        if monotonic() - self._gpu_updated_at < self._gpu_ttl_seconds:
            return
        with self._gpu_lock:
            if self._gpu_refreshing:
                return
            self._gpu_refreshing = True
        Thread(target=self._refresh_gpu, name="hardware-gpu-refresh", daemon=True).start()

    def _refresh_gpu(self) -> None:
        try:
            gpu = _collect_nvidia_gpu()
            with self._gpu_lock:
                self._gpu_snapshot = gpu
                self._gpu_updated_at = monotonic()
        finally:
            with self._gpu_lock:
                self._gpu_refreshing = False


def _unknown_snapshot() -> dict:
    return {
        "cpu": {"name": _cpu_name(), "cores": 0, "usagePercent": 0, "temperatureC": None},
        "gpu": _unknown_gpu(),
        "ram": {"totalMb": 0, "usedMb": 0},
        "disk": {"totalGb": 0, "freeGb": 0, "installPathFreeGb": 0},
        "timestamp": _utc_now(),
    }


def _unknown_gpu() -> dict:
    return {
        "name": "No NVIDIA GPU detected",
        "vendor": "unknown",
        "usagePercent": 0,
        "temperatureC": None,
        "vramTotalMb": 0,
        "vramUsedMb": 0,
        "driverVersion": "unknown",
    }


def _collect_nvidia_gpu() -> dict:
    query = ",".join(
        [
            "name",
            "driver_version",
            "utilization.gpu",
            "temperature.gpu",
            "memory.total",
            "memory.used",
        ]
    )
    try:
        result = subprocess.run(
            ["nvidia-smi", f"--query-gpu={query}", "--format=csv,noheader,nounits"],
            capture_output=True,
            text=True,
            timeout=0.75,
            check=False,
        )
    except (FileNotFoundError, subprocess.SubprocessError, OSError):
        return _unknown_gpu()
    if result.returncode != 0 or not result.stdout.strip():
        return _unknown_gpu()
    first_gpu = result.stdout.strip().splitlines()[0]
    fields = [field.strip() for field in first_gpu.split(",")]
    if len(fields) < 6:
        return _unknown_gpu()
    name, driver, utilization, temperature, memory_total, memory_used = fields[:6]
    return {
        "name": name or "NVIDIA GPU",
        "vendor": "NVIDIA",
        "usagePercent": _float_or_zero(utilization),
        "temperatureC": _float_or_none(temperature),
        "vramTotalMb": int(_float_or_zero(memory_total)),
        "vramUsedMb": int(_float_or_zero(memory_used)),
        "driverVersion": driver or "unknown",
    }


def _cpu_name() -> str:
    return os.environ.get("PROCESSOR_IDENTIFIER") or platform.processor() or platform.machine() or "Unknown CPU"


def _cpu_temperature() -> float | None:
    if psutil is None or not hasattr(psutil, "sensors_temperatures"):
        return None
    try:
        temperatures = psutil.sensors_temperatures(fahrenheit=False)
    except (AttributeError, OSError):
        return None
    for entries in temperatures.values():
        for entry in entries:
            current = getattr(entry, "current", None)
            if current is not None:
                return round(float(current), 1)
    return None


def _float_or_zero(value: str) -> float:
    try:
        return float(value)
    except ValueError:
        return 0.0


def _float_or_none(value: str) -> float | None:
    try:
        return float(value)
    except ValueError:
        return None


def _utc_now() -> str:
    return datetime.now(UTC).isoformat()


hardware_service = HardwareService()
