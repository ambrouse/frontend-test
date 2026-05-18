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
        (provider_root / "runtime" / ".gitkeep").touch()
        (provider_root / "logs" / ".gitkeep").touch()

        manifest_path = provider_root / "aihub.provider.json"
        if not manifest_path.exists():
            manifest_path.write_text(
                json.dumps(provider, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )

        config_path = provider_root / "config" / "default.json"
        if not config_path.exists():
            config_path.write_text(
                json.dumps(provider["editableConfig"], indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )

        for platform in ("windows", "linux"):
            script_dir = provider_root / "scripts" / platform
            if script_dir.exists():
                continue
            script_dir.mkdir(parents=True, exist_ok=True)
            for script_name in ("setup", "run", "stop", "health", "collect-metrics"):
                if platform == "windows":
                    (script_dir / f"{script_name}.ps1").write_text(WINDOWS_SCRIPT, encoding="utf-8")
                else:
                    (script_dir / f"{script_name}.sh").write_text(LINUX_SCRIPT, encoding="utf-8")

    print(f"Seeded {len(provider_seed())} providers into {providers_root}")


if __name__ == "__main__":
    main()
