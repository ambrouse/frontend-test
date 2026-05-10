from __future__ import annotations

import json
import sys

from app.core.paths import providers_root
from app.schemas.models import HubProject


def main() -> int:
    failures: list[str] = []
    manifests = sorted(providers_root().glob("*/aihub.provider.json"))
    if not manifests:
        failures.append("No provider manifests found")

    for manifest_path in manifests:
        try:
            data = json.loads(manifest_path.read_text(encoding="utf-8"))
            provider = HubProject.model_validate(data)
        except Exception as exc:  # pragma: no cover - command line report
            failures.append(f"{manifest_path}: {exc}")
            continue

        provider_dir = manifest_path.parent
        for platform_name, command_map in (("windows", provider.commands.windows), ("linux", provider.commands.linux)):
            for command_name in ("setup", "run", "stop", "health", "metrics"):
                command_path = command_map.get(command_name)
                if not command_path:
                    failures.append(f"{provider.id}: missing {platform_name}.{command_name}")
                    continue
                if not (provider_dir / command_path).exists():
                    failures.append(f"{provider.id}: missing script {command_path}")

        if provider.runtime and not provider.runtime.logFile:
            failures.append(f"{provider.id}: runtime.logFile is required")

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"Validated {len(manifests)} provider manifests")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
