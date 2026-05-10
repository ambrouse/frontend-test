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

export type TaskStatus = "installing" | "running" | "stopping" | "failed" | "completed";

export type LogLevel = "info" | "warn" | "error" | "debug";

export type HardwareSnapshot = {
  cpu: {
    name: string;
    cores: number;
    usagePercent: number;
    temperatureC: number;
  };
  gpu: {
    name: string;
    vendor: string;
    usagePercent: number;
    temperatureC: number;
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
