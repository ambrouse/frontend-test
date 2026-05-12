import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { ProjectDetailView } from "@/components/hub/ProjectDetailView";
import type { HardwareSnapshot, HubProject, ProviderConfig, ProviderLogsResponse, ProviderMetrics, ProviderStatus } from "@/services/types";

const project: HubProject = {
  id: "pdf-to-podcast",
  name: "PDF to Podcast",
  type: "speech",
  repoUrl: "https://github.com/PhuongHo03/pdf-to-podcast.git",
  description: "PDF to podcast provider",
  tags: ["pdf"],
  accentColor: "#14b8a6",
  visual: {
    imageUrl: "/assets/projects/embedding-foundry.jpg",
    focus: "50% 50%",
    ambient: "#14b8a6",
    ambientSoft: "#042f2e",
  },
  installStatus: "installed",
  runStatus: "stopped",
  requirements: {
    minimum: { cpuCores: 4, ramMb: 4096, vramMb: 0, diskGb: 10, gpuRequired: false },
    recommended: { cpuCores: 8, ramMb: 8192, vramMb: 0, diskGb: 20, gpuRequired: false },
  },
  editableConfig: { profile: "hosted", branch: "main", port: 7860, installDirectory: "deploy/pdf-to-podcast" },
  compatibility: { level: "green", reasons: ["ready"] },
  lastBenchmark: {
    headlineMetric: "0 jobs/min",
    secondaryMetric: "not started",
    latencyMs: 0,
    throughput: 0,
    vramPeakMb: 0,
    measuredAt: "2026-05-12T00:00:00.000Z",
  },
  lastRunAt: "2026-05-12T00:00:00.000Z",
};

const hardware: HardwareSnapshot = {
  cpu: { name: "CPU", cores: 12, usagePercent: 8, temperatureC: null },
  gpu: { name: "GPU", vendor: "NVIDIA", usagePercent: 0, temperatureC: null, vramTotalMb: 0, vramUsedMb: 0, driverVersion: "test" },
  ram: { totalMb: 32768, usedMb: 8192 },
  disk: { totalGb: 512, freeGb: 256, installPathFreeGb: 200 },
  timestamp: "2026-05-12T00:00:00.000Z",
};

const status: ProviderStatus = {
  projectId: "pdf-to-podcast",
  state: "installed",
  pid: null,
  port: 7860,
  platform: "windows",
  startedAt: null,
  uptimeSec: 0,
  currentStep: "Installed",
  progressPercent: 100,
  health: { level: "ok", message: "Installed" },
};

const metrics: ProviderMetrics = {
  sampledAt: "2026-05-12T00:00:00.000Z",
  platform: "windows",
  process: {},
  service: {},
  benchmark: { headlineMetric: "0 jobs/min", secondaryMetric: "not started" },
};

const config: ProviderConfig = {
  profile: "hosted",
  branch: "main",
  port: 7860,
  installDirectory: "deploy/pdf-to-podcast",
  env: {},
  warnings: [],
};

const logsResponse: ProviderLogsResponse = {
  cursor: 2,
  logs: [
    {
      id: "log-1",
      projectId: "pdf-to-podcast",
      source: "install",
      level: "info",
      timestamp: "2026-05-12T00:00:01.000Z",
      message: "Cloning source from GitHub",
    },
    {
      id: "log-2",
      projectId: "pdf-to-podcast",
      source: "runtime",
      level: "error",
      timestamp: "2026-05-12T00:00:02.000Z",
      message: "Detailed runtime error",
    },
  ],
};

vi.mock("@/services/apiClient", () => ({
  fetchHardwareSnapshot: vi.fn(() => Promise.resolve(hardware)),
  fetchActiveTasks: vi.fn(() => Promise.resolve({ tasks: [], total: 0 })),
  fetchProviderConfig: vi.fn(() => Promise.resolve(config)),
  fetchProviderDetail: vi.fn(() => Promise.resolve(project)),
  fetchProviderLogs: vi.fn(() => Promise.resolve(logsResponse)),
  fetchProviderMetrics: vi.fn(() => Promise.resolve(metrics)),
  fetchProviderStatus: vi.fn(() => Promise.resolve(status)),
  providerAction: vi.fn(() => Promise.resolve({ taskId: "task-1", status: "running", warnings: [] })),
}));

describe("ProjectDetailView provider activity", () => {
  it("separates progress updates from detailed log filtering", async () => {
    render(<ProjectDetailView projectId="pdf-to-podcast" project={project} />);

    expect(screen.getByRole("tab", { name: "Progress" })).toHaveAttribute("aria-selected", "true");
    await waitFor(() => expect(screen.getByText("Cloning source from GitHub")).toBeInTheDocument());

    fireEvent.click(screen.getByRole("tab", { name: "Detailed logs" }));

    expect(screen.getByRole("tab", { name: "Detailed logs" })).toHaveAttribute("aria-selected", "true");
    expect(screen.getByLabelText("Log filter")).toBeInTheDocument();
    expect(screen.getByText("Detailed runtime error")).toBeInTheDocument();
  });
});
