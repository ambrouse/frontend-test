import json
import subprocess

from app.core.paths import providers_root
from app.services import provider_registry as provider_registry_module
from app.services.provider_registry import ProviderRegistry, provider_registry


def test_featured_providers_are_deterministic() -> None:
    first = [provider.id for provider in provider_registry.featured(limit=10).providers]
    second = [provider.id for provider in provider_registry.featured(limit=10).providers]
    assert first == second


def test_query_filter() -> None:
    response = provider_registry.list_providers(query="AI-Q")
    assert response.total >= 1
    assert any("ai-q" in provider.name.lower() for provider in response.providers)


def test_provider_media_overrides_manifest_visual(tmp_path) -> None:
    provider_id = "sample-provider"
    provider_root = tmp_path / provider_id
    provider_root.mkdir()
    manifest = json.loads((providers_root() / "aiq" / "aihub.provider.json").read_text(encoding="utf-8"))
    manifest["id"] = provider_id
    manifest["name"] = "Sample Provider"
    (provider_root / "aihub.provider.json").write_text(json.dumps(manifest), encoding="utf-8")

    media_dir = provider_root / "media"
    media_dir.mkdir()
    (media_dir / "02-card.jpg").write_bytes(b"image")
    (media_dir / "01-banner.png").write_bytes(b"image")

    registry = ProviderRegistry(root=tmp_path, ttl_seconds=0)
    registry.refresh(force=True)
    provider = registry.get_provider(provider_id)

    assert provider is not None
    assert provider.visual.imageUrl == f"/api/providers/{provider_id}/assets/media/01-banner.png"
    assert provider.visual.gallery == [
        f"/api/providers/{provider_id}/assets/media/01-banner.png",
        f"/api/providers/{provider_id}/assets/media/02-card.jpg",
    ]


def test_tool_detection_marks_failing_command_unavailable(monkeypatch) -> None:
    provider_registry_module._TOOL_CACHE.clear()
    monkeypatch.setattr(provider_registry_module.shutil, "which", lambda _: "docker")

    def fake_run(*_args, **_kwargs):
        return subprocess.CompletedProcess(
            args=["docker", "info"],
            returncode=1,
            stdout="",
            stderr="Cannot connect to the Docker daemon",
        )

    monkeypatch.setattr(provider_registry_module.subprocess, "run", fake_run)

    detected = provider_registry_module._detect_tool("docker info")

    assert detected["available"] is False
    assert detected["version"] == "Cannot connect to the Docker daemon"
