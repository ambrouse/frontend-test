from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BACKEND_ROOT = ROOT / "backend"
sys.path.insert(0, str(BACKEND_ROOT))

from app.services.provider_seed import provider_seed  # noqa: E402

WINDOWS_SCRIPT = """param()
$ErrorActionPreference = "Stop"
$providerRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force -Path (Join-Path $providerRoot "runtime"), (Join-Path $providerRoot "logs") | Out-Null
Write-Output '{"ok":true,"message":"stub"}'
"""

LINUX_SCRIPT = """#!/usr/bin/env bash
set -euo pipefail
mkdir -p runtime logs
printf '{"ok":true,"message":"stub"}\n'
"""


def main() -> None:
    providers_root = ROOT / "providers"
    providers_root.mkdir(exist_ok=True)

    for provider in provider_seed():
        provider_root = providers_root / provider["id"]
        (provider_root / "config").mkdir(parents=True, exist_ok=True)
        (provider_root / "runtime").mkdir(parents=True, exist_ok=True)
        (provider_root / "logs").mkdir(parents=True, exist_ok=True)
        (provider_root / "scripts" / "windows").mkdir(parents=True, exist_ok=True)
        (provider_root / "scripts" / "linux").mkdir(parents=True, exist_ok=True)

        (provider_root / "aihub.provider.json").write_text(
            json.dumps(provider, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        (provider_root / "config" / "default.json").write_text(
            json.dumps(provider["editableConfig"], indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        (provider_root / "runtime" / ".gitkeep").write_text("", encoding="utf-8")
        (provider_root / "logs" / ".gitkeep").write_text("", encoding="utf-8")

        for script_name in ("setup", "run", "stop", "health", "collect-metrics"):
            (provider_root / "scripts" / "windows" / f"{script_name}.ps1").write_text(WINDOWS_SCRIPT, encoding="utf-8")
            linux_path = provider_root / "scripts" / "linux" / f"{script_name}.sh"
            linux_path.write_text(LINUX_SCRIPT, encoding="utf-8")

    print(f"Seeded {len(provider_seed())} providers into {providers_root}")


if __name__ == "__main__":
    main()
