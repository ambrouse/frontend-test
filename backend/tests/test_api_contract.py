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


def test_providers_contract() -> None:
    response = client.get("/api/providers")
    assert response.status_code == 200
    body = response.json()
    assert body["total"] >= 30
    first_provider = body["providers"][0]
    assert {"id", "name", "type", "requirements", "compatibility", "lastBenchmark"} <= set(first_provider)


def test_provider_detail_contract() -> None:
    response = client.get("/api/providers/local-llm-studio")
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == "local-llm-studio"
    assert body["editableConfig"]["port"] == 7860


def test_provider_asset_contract(tmp_path, monkeypatch) -> None:
    provider_id = "sample-provider"
    provider_root = tmp_path / provider_id
    provider_root.mkdir()
    manifest = json.loads((providers_root() / "local-llm-studio" / "aihub.provider.json").read_text(encoding="utf-8"))
    manifest["id"] = provider_id
    (provider_root / "aihub.provider.json").write_text(json.dumps(manifest), encoding="utf-8")
    media_dir = provider_root / "media"
    media_dir.mkdir()
    (media_dir / "01-banner.png").write_bytes(b"image")

    monkeypatch.setattr(routes_providers, "provider_registry", ProviderRegistry(root=tmp_path, ttl_seconds=0))

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
