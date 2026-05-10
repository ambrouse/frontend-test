from __future__ import annotations

from copy import deepcopy
from datetime import UTC, datetime
from threading import Lock
from time import monotonic
from typing import Any, cast

from app.schemas.models import HardwareSnapshot
from app.services.provider_seed import SEED_HARDWARE

try:
    import psutil
except ImportError:  # pragma: no cover
    psutil = None


class HardwareService:
    def __init__(self, ttl_seconds: float = 1.0) -> None:
        self._ttl_seconds = ttl_seconds
        self._lock = Lock()
        self._snapshot = HardwareSnapshot.model_validate(SEED_HARDWARE)
        self._updated_at = 0.0

    def snapshot(self) -> HardwareSnapshot:
        now = monotonic()
        if now - self._updated_at < self._ttl_seconds:
            return self._snapshot

        with self._lock:
            if now - self._updated_at >= self._ttl_seconds:
                self._snapshot = self._collect_fast_snapshot()
                self._updated_at = now
        return self._snapshot

    def _collect_fast_snapshot(self) -> HardwareSnapshot:
        if psutil is None:
            return self._snapshot

        seed: dict[str, Any] = deepcopy(SEED_HARDWARE)
        virtual_memory = psutil.virtual_memory()
        disk_usage = psutil.disk_usage(".")
        cpu_seed = cast(dict[str, Any], seed["cpu"])
        seed["cpu"] = {
            **cpu_seed,
            "cores": psutil.cpu_count(logical=True) or cpu_seed["cores"],
            "usagePercent": psutil.cpu_percent(interval=None),
        }
        seed["ram"] = {
            "totalMb": int(virtual_memory.total / 1024 / 1024),
            "usedMb": int(virtual_memory.used / 1024 / 1024),
        }
        seed["disk"] = {
            "totalGb": int(disk_usage.total / 1024 / 1024 / 1024),
            "freeGb": int(disk_usage.free / 1024 / 1024 / 1024),
            "installPathFreeGb": int(disk_usage.free / 1024 / 1024 / 1024),
        }
        seed["timestamp"] = datetime.now(UTC).isoformat()
        return HardwareSnapshot.model_validate(seed)


hardware_service = HardwareService()
