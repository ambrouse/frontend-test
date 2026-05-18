from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from typing import Any, cast

from app.schemas.models import HardwareSnapshot
from app.services.compatibility import evaluate_compatibility

OFFICIAL_PROVIDER_IDS = (
    "agentic-commerce-blueprint",
    "ai-virtual-assistant-provider",
    "aiq",
    "nemotron-voice-agent-provider",
    "shop-retail-provider",
    "multi-agent-intelligent-warehouse",
    "pdf-to-podcast",
)

SEED_HARDWARE = {
    "cpu": {"name": "AMD Ryzen 9 7950X", "cores": 16, "usagePercent": 38, "temperatureC": 61},
    "gpu": {
        "name": "NVIDIA RTX 4090",
        "vendor": "NVIDIA",
        "usagePercent": 46,
        "temperatureC": 68,
        "vramTotalMb": 24576,
        "vramUsedMb": 11320,
        "driverVersion": "560.94",
    },
    "ram": {"totalMb": 65536, "usedMb": 27480},
    "disk": {"totalGb": 2048, "freeGb": 842, "installPathFreeGb": 318},
    "timestamp": "2026-05-10T10:33:00.000Z",
}


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def _load_provider_manifest(provider_id: str) -> dict[str, Any]:
    import json

    path = _repo_root() / "providers" / provider_id / "aihub.provider.json"
    return cast(dict[str, Any], json.loads(path.read_text(encoding="utf-8-sig")))


def provider_seed() -> list[dict[str, Any]]:
    hardware = HardwareSnapshot.model_validate(SEED_HARDWARE)
    providers: list[dict[str, Any]] = []
    for provider_id in OFFICIAL_PROVIDER_IDS:
        provider = _load_provider_manifest(provider_id)
        requirements = cast(dict[str, Any], provider["requirements"])
        provider["compatibility"] = evaluate_compatibility(
            hardware,
            requirements["minimum"],
            requirements["recommended"],
        )
        providers.append(provider)
    return deepcopy(providers)


RUNNING_TASKS: list[dict[str, Any]] = []
