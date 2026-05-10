import { evaluateCompatibility } from "./compatibility";
import type { HardwareSnapshot, HubProject, ProjectLog, ProjectType, RunningTask } from "./types";

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
    accentColor: "#22d3ee",
    visual: {
      imageUrl: "/assets/projects/vision-lab.jpg",
      focus: "62% 72%",
      ambient: "#0284c7",
      ambientSoft: "#061f35",
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
    accentColor: "#2563eb",
    visual: {
      imageUrl: "/assets/projects/spark-llm.jpg",
      focus: "62% 48%",
      ambient: "#1d4ed8",
      ambientSoft: "#071936",
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
    accentColor: "#4ade80",
    visual: {
      imageUrl: "/assets/projects/nvidia-blueprint.jpg",
      focus: "54% 50%",
      ambient: "#22c55e",
      ambientSoft: "#052e16",
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

type GeneratedProjectDefinition = {
  id: string;
  name: string;
  type: ProjectType;
  visualType: ProjectType;
  description: string;
  tags: string[];
  accentColor: string;
  installStatus: HubProject["installStatus"];
  runStatus: HubProject["runStatus"];
  cpuCores: number;
  ramGb: number;
  vramGb: number;
  diskGb: number;
  gpuRequired?: boolean;
  profile: string;
  branch?: string;
  port: number;
  headlineMetric: string;
  secondaryMetric: string;
  throughput?: number;
  latencyMs?: number;
  vramPeakGb: number;
  lastRunAt: string;
};

type GeneratedProjectTuple = [
  id: string,
  name: string,
  type: ProjectType,
  visualType: ProjectType,
  description: string,
  tags: string[],
  accentColor: string,
  installStatus: HubProject["installStatus"],
  runStatus: HubProject["runStatus"],
  cpuCores: number,
  ramGb: number,
  vramGb: number,
  diskGb: number,
  gpuRequired: boolean,
  profile: string,
  branch: string | undefined,
  port: number,
  headlineMetric: string,
  secondaryMetric: string,
  throughput: number | undefined,
  latencyMs: number | undefined,
  vramPeakGb: number,
  lastRunAt: string,
];

const visualPresets = {
  llm: {
    imageUrl: "/assets/projects/local-llm.jpg",
    focus: "66% 48%",
    ambient: "#1f8c86",
    ambientSoft: "#0a2f31",
  },
  vision: {
    imageUrl: "/assets/projects/vision-lab.jpg",
    focus: "62% 72%",
    ambient: "#0284c7",
    ambientSoft: "#061f35",
  },
  "spark-llm": {
    imageUrl: "/assets/projects/spark-llm.jpg",
    focus: "62% 48%",
    ambient: "#1d4ed8",
    ambientSoft: "#071936",
  },
  "nvidia-blueprint": {
    imageUrl: "/assets/projects/nvidia-blueprint.jpg",
    focus: "54% 50%",
    ambient: "#22c55e",
    ambientSoft: "#052e16",
  },
  embedding: {
    imageUrl: "/assets/projects/embedding-foundry.jpg",
    focus: "64% 48%",
    ambient: "#31a8de",
    ambientSoft: "#08283b",
  },
  speech: {
    imageUrl: "/assets/projects/embedding-foundry.jpg",
    focus: "42% 48%",
    ambient: "#2563eb",
    ambientSoft: "#071936",
  },
  tooling: {
    imageUrl: "/assets/projects/local-llm.jpg",
    focus: "48% 50%",
    ambient: "#0f766e",
    ambientSoft: "#062827",
  },
} satisfies Record<ProjectType, HubProject["visual"]>;

const typeAccentColors: Record<ProjectType, string[]> = {
  llm: ["#2dd4bf", "#22c55e", "#38bdf8"],
  vision: ["#22d3ee", "#0ea5e9", "#2dd4bf"],
  "spark-llm": ["#2563eb", "#0284c7", "#38bdf8"],
  "nvidia-blueprint": ["#4ade80", "#22c55e", "#16a34a"],
  embedding: ["#38bdf8", "#0ea5e9", "#2dd4bf"],
  speech: ["#60a5fa", "#2563eb", "#38bdf8"],
  tooling: ["#0f766e", "#0284c7", "#22c55e"],
};

const generatedProjectDefinitions: GeneratedProjectDefinition[] = ([
  ["qwen-edge-server", "Qwen Edge Server", "llm", "llm", "Run Qwen edge profiles with OpenAI-compatible routing.", ["qwen", "edge", "api"], "#14b8a6", "installed", "stopped", 8, 24, 10, 42, true, "Qwen2.5 14B edge", "main", 8211, "61 tok/s", "TTFT 520 ms", 61, 520, 9, "2026-05-09T10:12:00.000Z"],
  ["llama-router-farm", "Llama Router Farm", "llm", "llm", "Route chat traffic across GGUF workers and fallback models.", ["llama", "router", "workers"], "#2dd4bf", "not_installed", "stopped", 10, 32, 12, 64, true, "Router balanced", "main", 8212, "184 req/min", "p95 1.8s", 184, 1800, 11, "2026-05-07T15:22:00.000Z"],
  ["deepseek-code-bench", "DeepSeek Code Bench", "llm", "llm", "Benchmark coding models against local repo prompts.", ["code", "eval", "deepseek"], "#60a5fa", "installed", "running", 12, 32, 16, 90, true, "Repo coding suite", "stable", 8213, "43 pass@1", "batch 128", 43, undefined, 14, "2026-05-10T08:10:00.000Z"],
  ["mixtral-quant-lab", "Mixtral Quant Lab", "llm", "llm", "Compare MoE quant profiles before installing full weights.", ["mixtral", "moe", "quant"], "#22c55e", "not_installed", "stopped", 14, 48, 20, 120, true, "MoE Q4 sweep", "main", 8214, "37 tok/s", "VRAM 18 GB", 37, undefined, 18, "2026-05-06T11:40:00.000Z"],
  ["camera-qa-studio", "Camera QA Studio", "vision", "vision", "Inspect camera frames with detection and caption review loops.", ["camera", "qa", "caption"], "#f97316", "installed", "stopped", 6, 16, 8, 28, true, "Realtime QA", "stable", 8221, "42 FPS", "p95 44 ms", 42, 44, 7, "2026-05-09T13:18:00.000Z"],
  ["defect-vision-cell", "Defect Vision Cell", "vision", "vision", "Detect small manufacturing defects from batched image folders.", ["defect", "yolo", "batch"], "#f59e0b", "not_installed", "stopped", 8, 24, 10, 60, true, "Factory batch", "main", 8222, "310 img/min", "mAP 0.72", 310, undefined, 9, "2026-05-04T09:25:00.000Z"],
  ["ocr-layout-forge", "OCR Layout Forge", "vision", "vision", "Parse screenshots and PDF pages into structured OCR regions.", ["ocr", "layout", "pdf"], "#fb923c", "installed", "stopped", 6, 16, 6, 32, true, "Document layout", "main", 8223, "96 pages/min", "p95 620 ms", 96, 620, 5, "2026-05-08T16:11:00.000Z"],
  ["sam-desk-segmenter", "SAM Desk Segmenter", "vision", "vision", "Segment objects from workstation screenshots and camera stills.", ["sam", "segment", "mask"], "#facc15", "not_installed", "stopped", 8, 24, 12, 72, true, "SAM desktop", "main", 8224, "28 masks/s", "batch 16", 28, undefined, 10, "2026-05-05T18:04:00.000Z"],
  ["spark-rag-indexer", "Spark RAG Indexer", "spark-llm", "spark-llm", "Build vector indexes from large folders with Spark executors.", ["spark", "rag", "index"], "#8b5cf6", "installed", "stopped", 12, 48, 12, 160, true, "Index workers", "main", 8231, "5.8k docs/min", "8 workers", 5800, undefined, 11, "2026-05-09T19:32:00.000Z"],
  ["batch-eval-orchestrator", "Batch Eval Orchestrator", "spark-llm", "spark-llm", "Queue prompt eval jobs and compare model output drift.", ["eval", "spark", "queue"], "#a78bfa", "not_installed", "stopped", 12, 48, 16, 140, true, "Eval queue", "main", 8232, "2.4k rows/min", "p95 7.1s", 2400, 7100, 15, "2026-05-03T12:20:00.000Z"],
  ["dataset-distill-runner", "Dataset Distill Runner", "spark-llm", "spark-llm", "Distill raw corpora into instruction datasets with GPU batches.", ["distill", "dataset", "etl"], "#c084fc", "installed", "running", 16, 64, 20, 220, true, "Distill pass", "stable", 8233, "820 pairs/min", "job p95 11s", 820, 11000, 19, "2026-05-10T07:44:00.000Z"],
  ["triton-blueprint-serve", "Triton Blueprint Serve", "nvidia-blueprint", "nvidia-blueprint", "Serve TensorRT engines through a Triton blueprint stack.", ["triton", "tensorrt", "serve"], "#84cc16", "not_installed", "stopped", 16, 64, 18, 180, true, "Triton single GPU", "release/1.x", 8241, "710 infer/s", "p95 24 ms", 710, 24, 17, "2026-05-06T20:36:00.000Z"],
  ["cuda-agent-workshop", "CUDA Agent Workshop", "nvidia-blueprint", "nvidia-blueprint", "Prototype GPU agent tools with CUDA telemetry and queues.", ["cuda", "agent", "telemetry"], "#65a30d", "installed", "stopped", 12, 48, 14, 120, true, "Agent lab", "main", 8242, "94 tasks/min", "VRAM 12 GB", 94, undefined, 12, "2026-05-08T08:45:00.000Z"],
  ["nemo-guardrail-stack", "NeMo Guardrail Stack", "nvidia-blueprint", "nvidia-blueprint", "Run local guardrail services for LLM policy tests.", ["nemo", "guardrail", "policy"], "#a3e635", "not_installed", "stopped", 10, 32, 10, 96, true, "Policy suite", "main", 8243, "390 checks/min", "p95 180 ms", 390, 180, 9, "2026-05-01T14:08:00.000Z"],
  ["vector-recall-bench", "Vector Recall Bench", "embedding", "embedding", "Measure recall and latency across local vector stores.", ["vector", "recall", "bench"], "#38bdf8", "installed", "stopped", 6, 16, 4, 44, false, "Recall sweep", "main", 8251, "14k q/min", "recall 0.91", 14000, undefined, 3, "2026-05-07T17:16:00.000Z"],
  ["reranker-arena", "Reranker Arena", "embedding", "embedding", "Compare local rerankers for RAG answer quality.", ["rerank", "rag", "score"], "#0ea5e9", "not_installed", "stopped", 8, 24, 8, 58, true, "Rerank suite", "main", 8252, "1.1k pairs/s", "nDCG 0.84", 1100, undefined, 7, "2026-05-02T10:05:00.000Z"],
  ["multilingual-speech-lab", "Multilingual Speech Lab", "speech", "speech", "Transcribe and align multilingual audio batches locally.", ["whisper", "speech", "align"], "#d946ef", "installed", "stopped", 8, 24, 8, 80, true, "Whisper large", "main", 8261, "18x realtime", "WER 7.4", 18, undefined, 7, "2026-05-09T22:10:00.000Z"],
  ["voice-clone-sandbox", "Voice Clone Sandbox", "speech", "speech", "Experiment with local voice profiles and safety gated export.", ["voice", "tts", "sandbox"], "#e879f9", "not_installed", "stopped", 10, 32, 12, 110, true, "TTS lab", "main", 8262, "31 clips/min", "p95 2.2s", 31, 2200, 11, "2026-05-04T21:34:00.000Z"],
  ["audio-diarization-node", "Audio Diarization Node", "speech", "speech", "Split speaker turns and export timeline JSON for meetings.", ["diarize", "speaker", "timeline"], "#60a5fa", "installed", "stopped", 8, 16, 6, 48, true, "Speaker timeline", "main", 8263, "9.8x realtime", "DER 6.2", 9.8, undefined, 5, "2026-05-08T23:20:00.000Z"],
  ["promptops-control-plane", "PromptOps Control Plane", "tooling", "tooling", "Track prompts, model configs, and local endpoint health.", ["promptops", "config", "health"], "#64748b", "installed", "running", 4, 8, 0, 16, false, "Control plane", "main", 8271, "12 endpoints", "live sync", 12, undefined, 1, "2026-05-10T06:28:00.000Z"],
  ["model-cache-manager", "Model Cache Manager", "tooling", "tooling", "Clean, pin, and move model caches across fast disks.", ["cache", "models", "disk"], "#94a3b8", "installed", "stopped", 4, 8, 0, 20, false, "Cache audit", "main", 8272, "318 GB free", "scan 9s", 318, 9000, 1, "2026-05-10T05:50:00.000Z"],
  ["agent-runbook-studio", "Agent Runbook Studio", "tooling", "tooling", "Manage repeatable local agent runbooks with health checks.", ["agent", "runbook", "health"], "#0f766e", "not_installed", "stopped", 4, 8, 0, 18, false, "Runbook base", "main", 8273, "42 runs/day", "success 96%", 42, undefined, 1, "2026-05-07T09:42:00.000Z"],
  ["gpu-observability-lite", "GPU Observability Lite", "tooling", "tooling", "Sample GPU, process, and queue metrics for dashboard panels.", ["gpu", "metrics", "dash"], "#0284c7", "installed", "running", 4, 8, 0, 12, false, "Telemetry agent", "main", 8274, "1s samples", "4 streams", 4, 1000, 1, "2026-05-10T04:18:00.000Z"],
  ["semantic-cache-proxy", "Semantic Cache Proxy", "embedding", "embedding", "Cache similar prompt responses using local embedding distance.", ["cache", "embedding", "proxy"], "#22c55e", "not_installed", "stopped", 6, 16, 4, 36, false, "Cache proxy", "main", 8253, "87% hits", "p95 42 ms", 87, 42, 3, "2026-05-06T15:27:00.000Z"],
  ["bluegreen-deploy-gateway", "Bluegreen Deploy Gateway", "tooling", "tooling", "Switch local provider endpoints between blue and green slots.", ["deploy", "gateway", "routing"], "#38bdf8", "installed", "stopped", 4, 8, 0, 24, false, "Bluegreen routes", "main", 8275, "24 routes", "swap 3s", 24, 3000, 1, "2026-05-05T06:35:00.000Z"],
] satisfies GeneratedProjectTuple[]).map(
  ([
    id,
    name,
    type,
    visualType,
    description,
    tags,
    accentColor,
    installStatus,
    runStatus,
    cpuCores,
    ramGb,
    vramGb,
    diskGb,
    gpuRequired,
    profile,
    branch,
    port,
    headlineMetric,
    secondaryMetric,
    throughput,
    latencyMs,
    vramPeakGb,
    lastRunAt,
  ]) => ({
    id,
    name,
    type,
    visualType,
    description,
    tags,
    accentColor,
    installStatus,
    runStatus,
    cpuCores,
    ramGb,
    vramGb,
    diskGb,
    gpuRequired,
    profile,
    branch,
    port,
    headlineMetric,
    secondaryMetric,
    throughput,
    latencyMs,
    vramPeakGb,
    lastRunAt,
  }),
) satisfies GeneratedProjectDefinition[];

const generatedProjects: Omit<HubProject, "compatibility">[] = generatedProjectDefinitions.map((project, index) => ({
  id: project.id,
  name: project.name,
  type: project.type,
  repoUrl: `https://github.com/ntc-ai/${project.id}`,
  description: project.description,
  tags: project.tags,
  accentColor: typeAccentColors[project.type][index % typeAccentColors[project.type].length],
  visual: visualPresets[project.visualType],
  installStatus: project.installStatus,
  runStatus: project.runStatus,
  requirements: {
    minimum: {
      cpuCores: project.cpuCores,
      ramMb: project.ramGb * 1024,
      vramMb: project.vramGb * 1024,
      diskGb: project.diskGb,
      gpuRequired: project.gpuRequired ?? true,
    },
    recommended: {
      cpuCores: project.cpuCores + 4,
      ramMb: project.ramGb * 2048,
      vramMb: project.vramGb * 2048,
      diskGb: Math.ceil(project.diskGb * 1.8),
      gpuRequired: project.gpuRequired ?? true,
    },
  },
  editableConfig: {
    profile: project.profile,
    branch: project.branch ?? "main",
    port: project.port,
    installDirectory: `D:/AIHub/providers/${project.id}`,
  },
  lastBenchmark: {
    headlineMetric: project.headlineMetric,
    secondaryMetric: project.secondaryMetric,
    latencyMs: project.latencyMs,
    throughput: project.throughput,
    vramPeakMb: project.vramPeakGb * 1024,
    measuredAt: project.lastRunAt,
  },
  lastRunAt: project.lastRunAt,
}));

export const hubProjects: HubProject[] = [...projectsSeed, ...generatedProjects].map((project) => ({
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
