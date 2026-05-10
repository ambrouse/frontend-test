from time import perf_counter

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _elapsed_ms(path: str, runs: int = 25) -> float:
    client.get(path)
    start = perf_counter()
    for _ in range(runs):
        response = client.get(path)
        assert response.status_code == 200
    return ((perf_counter() - start) / runs) * 1000


def test_provider_list_warm_path_is_fast() -> None:
    assert _elapsed_ms("/api/providers") < 25


def test_hardware_snapshot_warm_path_is_fast() -> None:
    assert _elapsed_ms("/api/hardware/snapshot") < 15
