import json

from app.core.paths import providers_root
from app.services.provider_registry import ProviderRegistry, provider_registry


def test_featured_providers_are_deterministic() -> None:
    first = [provider.id for provider in provider_registry.featured(limit=10).providers]
    second = [provider.id for provider in provider_registry.featured(limit=10).providers]
    assert first == second


def test_query_filter() -> None:
    response = provider_registry.list_providers(query="qwen")
    assert response.total >= 1
    assert any("qwen" in provider.name.lower() for provider in response.providers)


def test_provider_media_overrides_manifest_visual(tmp_path) -> None:
    provider_id = "sample-provider"
    provider_root = tmp_path / provider_id
    provider_root.mkdir()
    manifest = json.loads((providers_root() / "local-llm-studio" / "aihub.provider.json").read_text(encoding="utf-8"))
    manifest["id"] = provider_id
    manifest["name"] = "Sample Provider"
    (provider_root / "aihub.provider.json").write_text(json.dumps(manifest), encoding="utf-8")

    media_dir = provider_root / "media"
    media_dir.mkdir()
    (media_dir / "02-card.jpg").write_bytes(b"image")
    (media_dir / "01-banner.png").write_bytes(b"image")

    registry = ProviderRegistry(root=tmp_path, ttl_seconds=0)
    provider = registry.get_provider(provider_id)

    assert provider is not None
    assert provider.visual.imageUrl == f"/api/providers/{provider_id}/assets/media/01-banner.png"
    assert provider.visual.gallery == [
        f"/api/providers/{provider_id}/assets/media/01-banner.png",
        f"/api/providers/{provider_id}/assets/media/02-card.jpg",
    ]
