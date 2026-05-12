import { describe, expect, it, vi } from "vitest";
import { fetchProviders, getApiBase, resolveApiAssetUrl } from "@/services/apiClient";

describe("apiClient", () => {
  it("uses a local backend by default", () => {
    expect(getApiBase()).toBe("http://127.0.0.1:8000");
  });

  it("points backend asset URLs at the API host", () => {
    expect(resolveApiAssetUrl("/api/providers/demo/assets/media/01.png")).toBe(
      "http://127.0.0.1:8000/api/providers/demo/assets/media/01.png",
    );
    expect(resolveApiAssetUrl("/assets/projects/fallback.jpg")).toBe("/assets/projects/fallback.jpg");
  });

  it("returns provider response without blocking fallback callers", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValueOnce({
      ok: true,
      json: async () => ({ providers: [], total: 0, cacheVersion: 1 }),
    } as Response);

    await expect(fetchProviders({ timeoutMs: 1000 })).resolves.toEqual({
      providers: [],
      total: 0,
      cacheVersion: 1,
    });

    fetchMock.mockRestore();
  });
});
