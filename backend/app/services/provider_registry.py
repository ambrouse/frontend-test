from __future__ import annotations

import json
from pathlib import Path
from threading import Lock
from time import monotonic

from app.core.paths import providers_root
from app.schemas.models import HubProject, ProviderListResponse
from app.services.compatibility import evaluate_compatibility
from app.services.hardware import hardware_service
from app.services.provider_seed import provider_seed


class ProviderRegistry:
    def __init__(self, root: Path | None = None, ttl_seconds: float = 2.0) -> None:
        self._root = root or providers_root()
        self._ttl_seconds = ttl_seconds
        self._lock = Lock()
        self._providers = [HubProject.model_validate(provider) for provider in provider_seed()]
        self._cache_version = 1
        self._updated_at = 0.0

    def list_providers(self, project_type: str | None = None, query: str | None = None) -> ProviderListResponse:
        providers = self._warm_providers()
        normalized_query = (query or "").strip().lower()
        filtered = [
            provider
            for provider in providers
            if (not project_type or project_type == "all" or provider.type == project_type)
            and (
                not normalized_query
                or normalized_query in provider.name.lower()
                or normalized_query in provider.repoUrl.lower()
                or any(normalized_query in tag.lower() for tag in provider.tags)
            )
        ]
        return ProviderListResponse(providers=filtered, total=len(filtered), cacheVersion=self._cache_version)

    def featured(self, limit: int = 30) -> ProviderListResponse:
        providers = sorted(self._warm_providers(), key=lambda provider: _hash_id(provider.id))[:limit]
        return ProviderListResponse(providers=providers, total=len(providers), cacheVersion=self._cache_version)

    def get_provider(self, provider_id: str) -> HubProject | None:
        return next((provider for provider in self._warm_providers() if provider.id == provider_id), None)

    def provider_root(self, provider_id: str) -> Path:
        return self._root / provider_id

    def refresh(self) -> None:
        with self._lock:
            scanned = self._scan_provider_manifests()
            if scanned:
                self._providers = scanned
                self._cache_version += 1
            self._updated_at = monotonic()

    def _warm_providers(self) -> list[HubProject]:
        if monotonic() - self._updated_at > self._ttl_seconds:
            self.refresh()
        return self._providers

    def _scan_provider_manifests(self) -> list[HubProject]:
        if not self._root.exists():
            return []
        hardware = hardware_service.snapshot()
        providers: list[HubProject] = []
        for manifest_path in sorted(self._root.glob("*/aihub.provider.json")):
            with manifest_path.open("r", encoding="utf-8") as manifest_file:
                data = json.load(manifest_file)
            data["compatibility"] = evaluate_compatibility(
                hardware, data["requirements"]["minimum"], data["requirements"]["recommended"]
            )
            data = self._apply_runtime_overlay(manifest_path.parent, data)
            providers.append(HubProject.model_validate(data))
        return providers

    def _apply_runtime_overlay(self, provider_root: Path, data: dict) -> dict:
        status_path = provider_root / data.get("runtime", {}).get("statusFile", "runtime/status.json")
        if not status_path.exists():
            return data
        try:
            status = json.loads(status_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return data
        state = status.get("state")
        if state in {"installed", "running", "stopped"}:
            data["installStatus"] = "installed"
        elif state == "not_installed":
            data["installStatus"] = "not_installed"
        elif state == "failed":
            data["installStatus"] = "failed"
        if state == "running":
            data["runStatus"] = "running"
        elif state == "failed":
            data["runStatus"] = "error"
        else:
            data["runStatus"] = "stopped"
        return data


def _hash_id(provider_id: str) -> int:
    value = 0
    for char in provider_id:
        value = (value * 31 + ord(char)) % 997
    return value


provider_registry = ProviderRegistry()
