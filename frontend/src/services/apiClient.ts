import type {
  HardwareSnapshot,
  HubProject,
  ProviderActionResponse,
  ProviderConfig,
  ProviderLogsResponse,
  ProviderMetrics,
  ProviderStatus,
  ProviderSummary,
  RunningTask,
} from "./types";

const DEFAULT_API_BASE = "http://127.0.0.1:8000";
const FAST_TIMEOUT_MS = 1200;
const SELECTED_PROVIDER_CACHE_KEY = "hub-selected-provider-v1";

type ProviderListResponse = {
  providers: HubProject[];
  total: number;
  cacheVersion: number;
};

type ActiveTasksResponse = {
  count: number;
  tasks: RunningTask[];
};

type TasksResponse = {
  tasks: RunningTask[];
  total: number;
};

type ClearTasksResponse = {
  removed: number;
  scope: "finished" | "all";
};

export function getApiBase() {
  return (process.env.NEXT_PUBLIC_API_BASE ?? DEFAULT_API_BASE).replace(/\/$/, "");
}

export function resolveApiAssetUrl(url: string) {
  return url.startsWith("/api/") ? `${getApiBase()}${url}` : url;
}

export function cacheSelectedProvider(project: HubProject) {
  if (typeof window === "undefined") return;
  window.sessionStorage.setItem(SELECTED_PROVIDER_CACHE_KEY, JSON.stringify(project));
}

export function readSelectedProvider(providerId: string) {
  if (typeof window === "undefined") return null;
  const cachedRaw = window.sessionStorage.getItem(SELECTED_PROVIDER_CACHE_KEY);
  if (!cachedRaw) return null;
  try {
    const cached = JSON.parse(cachedRaw) as HubProject;
    return cached.id === providerId ? cached : null;
  } catch {
    window.sessionStorage.removeItem(SELECTED_PROVIDER_CACHE_KEY);
    return null;
  }
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

export async function fetchTasks(options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<TasksResponse>("/api/tasks", options);
}

export async function clearTaskHistory(scope: "finished" | "all" = "finished", options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<ClearTasksResponse>(`/api/tasks?scope=${scope}`, { ...options, method: "DELETE", timeoutMs: options?.timeoutMs ?? 1200 });
}

export async function fetchHardwareSnapshot(options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<HardwareSnapshot>("/api/hardware/snapshot", options);
}

export async function fetchProviderSummary(options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<ProviderSummary>("/api/providers/summary", options);
}

export async function fetchProviderDetail(providerId: string, options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<HubProject>(`/api/providers/${providerId}`, options);
}

export async function fetchProviderStatus(providerId: string, options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<ProviderStatus>(`/api/providers/${providerId}/status`, options);
}

export async function fetchProviderMetrics(providerId: string, options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<ProviderMetrics>(`/api/providers/${providerId}/metrics`, options);
}

export async function fetchProviderLogs(
  providerId: string,
  options?: { signal?: AbortSignal; timeoutMs?: number; level?: string; cursor?: number },
) {
  const params = new URLSearchParams();
  if (options?.level && options.level !== "all") params.set("level", options.level);
  if (typeof options?.cursor === "number") params.set("cursor", `${options.cursor}`);
  const suffix = params.size ? `?${params.toString()}` : "";
  return fetchJson<ProviderLogsResponse>(`/api/providers/${providerId}/logs${suffix}`, options);
}

export async function fetchProviderConfig(providerId: string, options?: { signal?: AbortSignal; timeoutMs?: number }) {
  return fetchJson<ProviderConfig>(`/api/providers/${providerId}/config`, options);
}

export async function patchProviderConfig(providerId: string, patch: Partial<ProviderConfig>) {
  return fetchJson<ProviderConfig>(`/api/providers/${providerId}/config`, { method: "PATCH", body: patch, timeoutMs: 1500 });
}

export async function providerAction(providerId: string, action: "install" | "run" | "stop" | "delete", body: Record<string, unknown> = {}) {
  const method = action === "delete" ? "DELETE" : "POST";
  const path = action === "delete" ? `/api/providers/${providerId}` : `/api/providers/${providerId}/${action}`;
  return fetchJson<ProviderActionResponse>(path, { method, body, timeoutMs: 1500 });
}

async function fetchJson<T>(
  path: string,
  options: { signal?: AbortSignal; timeoutMs?: number; method?: string; body?: unknown } = {},
) {
  const timeoutMs = options.timeoutMs ?? FAST_TIMEOUT_MS;
  const controller = new AbortController();
  const timeoutId = window.setTimeout(() => controller.abort(), timeoutMs);

  const abortHandler = () => controller.abort();
  options.signal?.addEventListener("abort", abortHandler, { once: true });

  try {
    const response = await fetch(`${getApiBase()}${path}`, {
      method: options.method ?? "GET",
      headers: { Accept: "application/json", ...(options.body ? { "Content-Type": "application/json" } : {}) },
      body: options.body ? JSON.stringify(options.body) : undefined,
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
