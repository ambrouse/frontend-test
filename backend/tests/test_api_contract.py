import json

from fastapi.testclient import TestClient

from app.api import routes_providers
from app.core.paths import providers_root
from app.main import app
from app.services.provider_registry import ProviderRegistry

client = TestClient(app)


def test_health_contract() -> None:
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"ok": True}


def test_local_dev_cors_allows_next_fallback_port() -> None:
    response = client.options(
        "/api/providers",
        headers={
            "Origin": "http://localhost:3001",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:3001"


def test_providers_contract() -> None:
    response = client.get("/api/providers")
    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 7
    provider_ids = {provider["id"] for provider in body["providers"]}
    assert provider_ids == {
        "agentic-commerce-blueprint",
        "ai-virtual-assistant-provider",
        "aiq",
        "nemotron-voice-agent-provider",
        "shop-retail-provider",
        "multi-agent-intelligent-warehouse",
        "pdf-to-podcast",
    }
    first_provider = body["providers"][0]
    assert {"id", "name", "type", "requirements", "compatibility", "lastBenchmark"} <= set(first_provider)


def test_provider_detail_contract() -> None:
    response = client.get("/api/providers/aiq")
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == "aiq"
    assert body["editableConfig"]["port"] == 13080


def test_removed_provider_returns_404() -> None:
    response = client.get("/api/providers/local-llm-studio")
    assert response.status_code == 404


def test_provider_asset_contract(tmp_path, monkeypatch) -> None:
    provider_id = "sample-provider"
    provider_root = tmp_path / provider_id
    provider_root.mkdir()
    manifest = json.loads((providers_root() / "aiq" / "aihub.provider.json").read_text(encoding="utf-8"))
    manifest["id"] = provider_id
    (provider_root / "aihub.provider.json").write_text(json.dumps(manifest), encoding="utf-8")
    media_dir = provider_root / "media"
    media_dir.mkdir()
    (media_dir / "01-banner.png").write_bytes(b"image")

    monkeypatch.setattr(routes_providers, "provider_registry", ProviderRegistry(root=tmp_path, ttl_seconds=0))
    routes_providers.provider_registry.refresh(force=True)

    detail_response = client.get(f"/api/providers/{provider_id}")
    assert detail_response.status_code == 200
    assert detail_response.json()["visual"]["imageUrl"] == f"/api/providers/{provider_id}/assets/media/01-banner.png"

    asset_response = client.get(f"/api/providers/{provider_id}/assets/media/01-banner.png")
    assert asset_response.status_code == 200
    assert asset_response.content == b"image"


def test_hardware_contract() -> None:
    response = client.get("/api/hardware/snapshot")
    assert response.status_code == 200
    body = response.json()
    assert body["cpu"]["cores"] > 0
    assert body["ram"]["totalMb"] > 0
