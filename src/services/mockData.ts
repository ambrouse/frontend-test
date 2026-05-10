import { evaluateCompatibility } from "./compatibility";
import type { HardwareSnapshot, HubProject, ProjectLog, RunningTask } from "./types";

export const hardwareSnapshot: HardwareSnapshot = {
  cpu: {
    name: "AMD Ryzen 9 7950X",
    cores: 16,
    usagePercent: 38,
    temperatureC: 61,
  },
  gpu: {
    name: "NVIDIA RTX 4090",
    vendor: "NVIDIA",
    usagePercent: 46,
    temperatureC: 68,
    vramTotalMb: 24576,
    vramUsedMb: 11320,
    driverVersion: "560.94",
  },
  ram: {
    totalMb: 65536,
    usedMb: 27480,
  },
  disk: {
    totalGb: 2048,
    freeGb: 842,
    installPathFreeGb: 318,
  },
  timestamp: "2026-05-10T10:33:00.000Z",
};

const projectsSeed: Omit<HubProject, "compatibility">[] = [
  {
    id: "local-llm-studio",
    name: "Local LLM Studio",
    type: "llm",
    repoUrl: "https://github.com/ntc-ai/local-llm-studio",
    description: "Serve Llama, Qwen, DeepSeek và các model GGUF bằng profile quantized.",
    tags: ["gguf", "llama.cpp", "chat"],
    accentColor: "#5eead4",
    visual: {
      imageUrl: "/assets/projects/local-llm.jpg",
      focus: "66% 48%",
      ambient: "#1f8c86",
      ambientSoft: "#0a2f31",
    },
    installStatus: "installed",
    runStatus: "running",
    requirements: {
      minimum: {
        cpuCores: 8,
        ramMb: 16384,
        vramMb: 8192,
        diskGb: 24,
        gpuRequired: true,
        notes: "Profile Q4 cho model 7B-14B.",
      },
      recommended: {
        cpuCores: 12,
        ramMb: 32768,
        vramMb: 16000,
        diskGb: 80,
        gpuRequired: true,
      },
    },
    editableConfig: {
      profile: "Qwen 14B Q4_K_M",
      branch: "main",
      port: 7860,
      installDirectory: "D:/AIHub/providers/local-llm-studio",
    },
    lastBenchmark: {
      headlineMetric: "72.4 tok/s",
      secondaryMetric: "TTFT 410 ms",
      latencyMs: 410,
      throughput: 72.4,
      vramPeakMb: 14820,
      measuredAt: "2026-05-10T09:12:00.000Z",
    },
    lastRunAt: "2026-05-10T09:12:00.000Z",
  },
  {
    id: "vision-lab",
    name: "Vision Lab",
    type: "vision",
    repoUrl: "https://github.com/ntc-ai/vision-lab",
    description: "Pipeline detection, segmentation và captioning cho camera hoặc batch ảnh.",
    tags: ["yolo", "sam", "caption"],
    accentColor: "#f59e0b",
    visual: {
      imageUrl: "/assets/projects/vision-lab.jpg",
      focus: "62% 54%",
      ambient: "#d58a24",
      ambientSoft: "#2f1b0b",
    },
    installStatus: "installed",
    runStatus: "stopped",
    requirements: {
      minimum: {
        cpuCores: 6,
        ramMb: 12288,
        vramMb: 6144,
        diskGb: 18,
        gpuRequired: true,
      },
      recommended: {
        cpuCores: 10,
        ramMb: 24576,
        vramMb: 12288,
        diskGb: 48,
        gpuRequired: true,
      },
    },
    editableConfig: {
      profile: "Realtime 1080p",
      branch: "stable",
      port: 8077,
      installDirectory: "D:/AIHub/providers/vision-lab",
    },
    lastBenchmark: {
      headlineMetric: "58 FPS",
      secondaryMetric: "p95 34 ms",
      latencyMs: 34,
      throughput: 58,
      vramPeakMb: 10450,
      measuredAt: "2026-05-09T17:30:00.000Z",
    },
    lastRunAt: "2026-05-09T17:30:00.000Z",
  },
  {
    id: "spark-llm-runner",
    name: "Spark LLM Runner",
    type: "spark-llm",
    repoUrl: "https://github.com/ntc-ai/spark-llm-runner",
    description: "Chạy batch inference LLM qua Spark cho dữ liệu lớn và job phân tán.",
    tags: ["spark", "batch", "etl"],
    accentColor: "#a78bfa",
    visual: {
      imageUrl: "/assets/projects/spark-llm.jpg",
      focus: "62% 48%",
      ambient: "#7c6df0",
      ambientSoft: "#181230",
    },
    installStatus: "not_installed",
    runStatus: "stopped",
    requirements: {
      minimum: {
        cpuCores: 12,
        ramMb: 32768,
        vramMb: 12000,
        diskGb: 96,
        gpuRequired: true,
      },
      recommended: {
        cpuCores: 16,
        ramMb: 65536,
        vramMb: 20000,
        diskGb: 180,
        gpuRequired: true,
      },
    },
    editableConfig: {
      profile: "Single node executor",
      branch: "main",
      port: 9091,
      installDirectory: "D:/AIHub/providers/spark-llm-runner",
    },
    lastBenchmark: {
      headlineMetric: "1.9k rows/min",
      secondaryMetric: "job p95 8.6s",
      latencyMs: 8600,
      throughput: 1900,
      vramPeakMb: 18600,
      measuredAt: "2026-05-05T12:44:00.000Z",
    },
    lastRunAt: "2026-05-05T12:44:00.000Z",
  },
  {
    id: "nvidia-blueprint-rag",
    name: "NVIDIA Blueprint RAG",
    type: "nvidia-blueprint",
    repoUrl: "https://github.com/ntc-ai/nvidia-blueprint-rag",
    description: "Blueprint RAG containerized với vector store, reranker và endpoint OpenAI-compatible.",
    tags: ["nvidia", "rag", "containers"],
    accentColor: "#84cc16",
    visual: {
      imageUrl: "/assets/projects/nvidia-blueprint.jpg",
      focus: "54% 50%",
      ambient: "#79b81e",
      ambientSoft: "#17250b",
    },
    installStatus: "failed",
    runStatus: "error",
    requirements: {
      minimum: {
        cpuCores: 12,
        ramMb: 49152,
        vramMb: 22000,
        diskGb: 220,
        gpuRequired: true,
      },
      recommended: {
        cpuCores: 24,
        ramMb: 98304,
        vramMb: 48000,
        diskGb: 420,
        gpuRequired: true,
      },
    },
    editableConfig: {
      profile: "Blueprint default",
      branch: "release/2.x",
      port: 8010,
      installDirectory: "D:/AIHub/providers/nvidia-blueprint-rag",
    },
    lastBenchmark: {
      headlineMetric: "Service failed",
      secondaryMetric: "VRAM gate",
      vramPeakMb: 22600,
      measuredAt: "2026-05-08T20:10:00.000Z",
    },
    lastRunAt: "2026-05-08T20:10:00.000Z",
  },
  {
    id: "embedding-foundry",
    name: "Embedding Foundry",
    type: "embedding",
    repoUrl: "https://github.com/ntc-ai/embedding-foundry",
    description: "Tạo embedding local, benchmark batch size và quản lý vector profile.",
    tags: ["embedding", "vector", "batch"],
    accentColor: "#38bdf8",
    visual: {
      imageUrl: "/assets/projects/embedding-foundry.jpg",
      focus: "64% 48%",
      ambient: "#31a8de",
      ambientSoft: "#08283b",
    },
    installStatus: "not_installed",
    runStatus: "stopped",
    requirements: {
      minimum: {
        cpuCores: 4,
        ramMb: 8192,
        vramMb: 2048,
        diskGb: 12,
        gpuRequired: false,
      },
      recommended: {
        cpuCores: 8,
        ramMb: 16384,
        vramMb: 6144,
        diskGb: 36,
        gpuRequired: false,
      },
    },
    editableConfig: {
      profile: "bge-m3 batch 64",
      branch: "main",
      port: 8120,
      installDirectory: "D:/AIHub/providers/embedding-foundry",
    },
    lastBenchmark: {
      headlineMetric: "1.2k vec/s",
      secondaryMetric: "batch 64",
      throughput: 1200,
      vramPeakMb: 3980,
      measuredAt: "2026-05-07T14:20:00.000Z",
    },
    lastRunAt: "2026-05-07T14:20:00.000Z",
  },
];

export const hubProjects: HubProject[] = projectsSeed.map((project) => ({
  ...project,
  compatibility: evaluateCompatibility(
    hardwareSnapshot,
    project.requirements.minimum,
    project.requirements.recommended,
  ),
}));

export const runningTasks: RunningTask[] = [
  {
    id: "task-llm-chat",
    projectId: "local-llm-studio",
    projectName: "Local LLM Studio",
    type: "llm",
    status: "running",
    startedAt: "2026-05-10T09:42:00.000Z",
    durationSec: 3120,
    cpuPercent: 18,
    gpuPercent: 42,
    ramMb: 9140,
    vramMb: 12680,
    currentStep: "Serving chat endpoint",
    progressPercent: 100,
  },
  {
    id: "task-vision-cache",
    projectId: "vision-lab",
    projectName: "Vision Lab",
    type: "vision",
    status: "completed",
    startedAt: "2026-05-10T08:58:00.000Z",
    durationSec: 740,
    cpuPercent: 4,
    gpuPercent: 0,
    ramMb: 1200,
    vramMb: 0,
    currentStep: "Dataset cache ready",
    progressPercent: 100,
  },
];

export const projectLogs: ProjectLog[] = [
  {
    id: "log-1",
    projectId: "local-llm-studio",
    source: "runtime",
    level: "info",
    timestamp: "2026-05-10T09:42:18.000Z",
    message: "Loaded Qwen 14B Q4_K_M with 32768 context tokens.",
  },
  {
    id: "log-2",
    projectId: "local-llm-studio",
    source: "runtime",
    level: "debug",
    timestamp: "2026-05-10T09:42:22.000Z",
    message: "CUDA graph warmup completed in 3.4s.",
  },
  {
    id: "log-3",
    projectId: "local-llm-studio",
    source: "runtime",
    level: "info",
    timestamp: "2026-05-10T09:44:02.000Z",
    message: "OpenAI-compatible endpoint available on http://localhost:7860/v1.",
  },
  {
    id: "log-4",
    projectId: "nvidia-blueprint-rag",
    source: "install",
    level: "warn",
    timestamp: "2026-05-08T20:04:31.000Z",
    message: "Container image pulled, but recommended VRAM threshold was not met.",
  },
  {
    id: "log-5",
    projectId: "nvidia-blueprint-rag",
    source: "runtime",
    level: "error",
    timestamp: "2026-05-08T20:10:19.000Z",
    message: "Reranker service exited after CUDA out-of-memory.",
  },
];

export function getProjectById(projectId: string) {
  return hubProjects.find((project) => project.id === projectId);
}

export function getProjectLogs(projectId: string) {
  return projectLogs.filter((log) => log.projectId === projectId);
}
