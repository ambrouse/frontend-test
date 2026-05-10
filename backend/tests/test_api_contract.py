from fastapi.testclient import TestClient

from app.main import app


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


def test_hardware_contract() -> None:
    response = client.get("/api/hardware/snapshot")
    assert response.status_code == 200
    body = response.json()
    assert body["cpu"]["cores"] > 0
    assert body["ram"]["totalMb"] > 0
