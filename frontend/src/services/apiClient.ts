import type { HardwareSnapshot, HubProject, RunningTask } from "./types";

const DEFAULT_API_BASE = "http://127.0.0.1:8000";
const FAST_TIMEOUT_MS = 250;

type ProviderListResponse = {
  providers: HubProject[];
  total: number;
  cacheVersion: number;
};

type ActiveTasksResponse = {
  count: number;
  tasks: RunningTask[];
};

export function getApiBase() {
  return (process.env.NEXT_PUBLIC_API_BASE ?? DEFAULT_API_BASE).replace(/\/$/, "");
}

export async function fetchProviders(options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<ProviderListResponse>("/api/providers", options);
}

export async function fetchFeaturedProviders(options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<ProviderListResponse>("/api/providers/featured", options);
}

export async function fetchActiveTasks(options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<ActiveTasksResponse>("/api/tasks/active", options);
}

export async function fetchHardwareSnapshot(options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<HardwareSnapshot>("/api/hardware/snapshot", options);
}

async function fetchJson<T>(path: string, options: { signal?: AbortSignal; timeoutMs?: number } = {}) {
  const timeoutMs = options.timeoutMs ?? FAST_TIMEOUT_MS;
  const controller = new AbortController();
  const timeoutId = window.setTimeout(() => controller.abort(), timeoutMs);

  const abortHandler = () => controller.abort();
  options.signal?.addEventListener("abort", abortHandler, { once: true });

  try {
    const response = await fetch(`${getApiBase()}${path}`, {
      headers: { Accept: "application/json" },
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`API ${path} failed with ${response.status}`);
    }

    return (await response.json()) as T;
  } finally {
    window.clearTimeout(timeoutId);
    options.signal?.removeEventListener("abort", abortHandler);
  }
}
