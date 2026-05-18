export type ProjectType =
  | "llm"
  | "vision"
  | "spark-llm"
  | "nvidia-blueprint"
  | "embedding"
  | "speech"
  | "tooling";

export type CompatibilityLevel = "green" | "yellow" | "red";

export type InstallStatus = "not_installed" | "installed" | "installing" | "failed";

export type RunStatus = "stopped" | "running" | "error";

export type TaskStatus = "queued" | "installing" | "running" | "stopping" | "deleting" | "failed" | "completed";

export type LogLevel = "info" | "warn" | "error" | "debug";

export type HardwareSnapshot = {
  cpu: {
    name: string;
    cores: number;
    usagePercent: number;
    temperatureC: number | null;
  };
  gpu: {
    name: string;
    vendor: string;
    usagePercent: number;
    temperatureC: number | null;
    vramTotalMb: number;
    vramUsedMb: number;
    driverVersion: string;
  };
  ram: {
    totalMb: number;
    usedMb: number;
  };
  disk: {
    totalGb: number;
    freeGb: number;
    installPathFreeGb: number;
  };
  timestamp: string;
};

export type RequirementProfile = {
  cpuCores: number;
  ramMb: number;
  vramMb: number;
  diskGb: number;
  gpuRequired: boolean;
  notes?: string;
};

export type Benchmark = {
  headlineMetric: string;
  secondaryMetric: string;
  latencyMs?: number;
  throughput?: number;
  vramPeakMb: number;
  measuredAt: string;
};

export type ToolRequirement = {
  id: string;
  label: string;
  command: string;
  required: boolean;
  minimumVersion?: string | null;
  installHint?: string | null;
  available?: boolean | null;
  version?: string | null;
};

export type RuntimeMode = {
  id: string;
  label: string;
  description: string;
  requiresGpu: boolean;
  requiresNvidiaKey: boolean;
};

export type ProviderEnvironment = {
  supportedOs: string[];
  architectures: string[];
  frameworks: string[];
  requiredTools: ToolRequirement[];
  runtimeModes: RuntimeMode[];
  setupNotes: string[];
  readiness?: {
    level: CompatibilityLevel;
    os: string;
    architecture: string;
    reasons: string[];
  } | null;
};

export type ProviderCommandSet = Partial<Record<"setup" | "run" | "stop" | "delete" | "health" | "metrics", string>>;

export type ProviderCommands = Partial<Record<"windows" | "linux", ProviderCommandSet>>;

export type HubProject = {
  id: string;
  name: string;
  type: ProjectType;
  repoUrl: string;
  description: string;
  tags: string[];
  accentColor: string;
  visual: {
    imageUrl: string;
    focus: string;
    ambient: string;
    ambientSoft: string;
    gallery?: string[];
  };
  installStatus: InstallStatus;
  runStatus: RunStatus;
  requirements: {
    minimum: RequirementProfile;
    recommended: RequirementProfile;
  };
  editableConfig: {
    profile: string;
    branch: string;
    port: number;
    installDirectory: string;
  };
  compatibility: {
    level: CompatibilityLevel;
    reasons: string[];
  };
  lastBenchmark: Benchmark;
  lastRunAt: string;
  runtime?: {
    defaultPort: number;
    healthUrl?: string;
    metricsUrl?: string;
    statusFile: string;
    metricsFile: string;
    pidFile: string;
    logFile: string;
  };
  environment?: ProviderEnvironment | null;
  commands?: ProviderCommands;
};

export type RunningTask = {
  id: string;
  projectId: string;
  projectName: string;
  type: ProjectType;
  status: TaskStatus;
  startedAt: string;
  durationSec: number;
  cpuPercent: number;
  gpuPercent: number;
  ramMb: number;
  vramMb: number;
  currentStep: string;
  progressPercent: number;
};

export type ProjectLog = {
  id: string;
  projectId: string;
  source: "install" | "runtime" | "system";
  level: LogLevel;
  timestamp: string;
  message: string;
};

export type ProviderSummary = {
  total: number;
  ready: number;
  blocked: number;
  installed: number;
  running: number;
};

export type ProviderStatus = {
  projectId: string;
  state: string;
  pid: number | null;
  port: number;
  platform: string;
  startedAt: string | null;
  uptimeSec: number;
  currentStep: string;
  progressPercent: number;
  health: {
    level?: string;
    message?: string;
  };
};

export type ProviderMetrics = {
  sampledAt: string;
  platform: string;
  process: Record<string, number>;
  service: Record<string, number>;
  benchmark: Record<string, string | number>;
};

export type ProviderConfig = {
  profile: string;
  branch: string;
  port: number;
  installDirectory: string;
  env: Record<string, string>;
  warnings: string[];
};

export type ProviderActionResponse = {
  taskId: string;
  status: TaskStatus;
  warnings: string[];
};

export type ProviderLogsResponse = {
  logs: ProjectLog[];
  cursor: number;
};
