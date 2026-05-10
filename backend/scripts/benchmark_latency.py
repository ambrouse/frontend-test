from __future__ import annotations

import argparse
import statistics
import sys
import time
from collections.abc import Iterable

from fastapi.testclient import TestClient

from app.main import app


def percentile(values: list[float], pct: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = min(len(ordered) - 1, max(0, round((pct / 100) * (len(ordered) - 1))))
    return ordered[index]


def timed_requests(client: TestClient, path: str, iterations: int) -> list[float]:
    durations: list[float] = []
    for _ in range(iterations):
        start = time.perf_counter()
        response = client.get(path)
        elapsed_ms = (time.perf_counter() - start) * 1000
        response.raise_for_status()
        durations.append(elapsed_ms)
    return durations


def benchmark_paths(provider_id: str | None) -> list[str]:
    paths = [
        "/api/health",
        "/api/hardware/snapshot",
        "/api/providers",
        "/api/providers/featured",
    ]
    if provider_id:
        paths.extend(
            [
                f"/api/providers/{provider_id}",
                f"/api/providers/{provider_id}/status",
                f"/api/providers/{provider_id}/logs?tail=20",
                f"/api/providers/{provider_id}/metrics",
            ]
        )
    return paths


def print_table(rows: Iterable[tuple[str, list[float]]]) -> bool:
    ok = True
    print("path,p50_ms,p95_ms,p99_ms,max_ms")
    for path, durations in rows:
        p50 = statistics.median(durations)
        p95 = percentile(durations, 95)
        p99 = percentile(durations, 99)
        max_ms = max(durations)
        print(f"{path},{p50:.2f},{p95:.2f},{p99:.2f},{max_ms:.2f}")
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description="Benchmark warm FastAPI endpoint latency.")
    parser.add_argument("--iterations", type=int, default=120)
    parser.add_argument("--warmup", type=int, default=10)
    parser.add_argument("--threshold-ms", type=float, default=100.0)
    parser.add_argument("--provider-id", default="agentic-commerce-blueprint")
    args = parser.parse_args()

    client = TestClient(app)
    paths = benchmark_paths(args.provider_id)
    for path in paths:
        timed_requests(client, path, args.warmup)

    failures: list[str] = []
    rows: list[tuple[str, list[float]]] = []
    for path in paths:
        durations = timed_requests(client, path, args.iterations)
        rows.append((path, durations))
        p95 = percentile(durations, 95)
        if p95 > args.threshold_ms:
            failures.append(f"{path} p95 {p95:.2f}ms > {args.threshold_ms:.2f}ms")

    print_table(rows)
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
