from typing import Literal

from pydantic import BaseModel, Field

ProjectType = Literal["llm", "vision", "spark-llm", "nvidia-blueprint", "embedding", "speech", "tooling"]
CompatibilityLevel = Literal["green", "yellow", "red"]
InstallStatus = Literal["not_installed", "installed", "installing", "failed"]
RunStatus = Literal["stopped", "running", "error"]
TaskStatus = Literal["installing", "running", "stopping", "failed", "completed"]
LogLevel = Literal["info", "warn", "error", "debug"]


class CpuSnapshot(BaseModel):
    name: str
    cores: int
    usagePercent: float
    temperatureC: float | None = None


class GpuSnapshot(BaseModel):
    name: str
    vendor: str
    usagePercent: float
    temperatureC: float | None = None
    vramTotalMb: int
    vramUsedMb: int
    driverVersion: str


class RamSnapshot(BaseModel):
    totalMb: int
    usedMb: int


class DiskSnapshot(BaseModel):
    totalGb: int
    freeGb: int
    installPathFreeGb: int


class HardwareSnapshot(BaseModel):
    cpu: CpuSnapshot
    gpu: GpuSnapshot
    ram: RamSnapshot
    disk: DiskSnapshot
    timestamp: str


class RequirementProfile(BaseModel):
    cpuCores: int
    ramMb: int
    vramMb: int
    diskGb: int
    gpuRequired: bool
    notes: str | None = None


class Benchmark(BaseModel):
    headlineMetric: str
    secondaryMetric: str
    latencyMs: float | None = None
    throughput: float | None = None
    vramPeakMb: int
    measuredAt: str


class ProviderVisual(BaseModel):
    imageUrl: str
    focus: str
    ambient: str
    ambientSoft: str


class EditableConfig(BaseModel):
    profile: str
    branch: str
    port: int
    installDirectory: str


class Compatibility(BaseModel):
    level: CompatibilityLevel
    reasons: list[str]


class Requirements(BaseModel):
    minimum: RequirementProfile
    recommended: RequirementProfile


class ProviderRuntime(BaseModel):
    defaultPort: int
    healthUrl: str | None = None
    metricsUrl: str | None = None
    statusFile: str = "runtime/status.json"
    metricsFile: str = "runtime/metrics.json"
    pidFile: str = "runtime/provider.pid"
    logFile: str = "logs/runtime.log"


class ProviderCommands(BaseModel):
    windows: dict[str, str] = Field(default_factory=dict)
    linux: dict[str, str] = Field(default_factory=dict)


class HubProject(BaseModel):
    id: str
    name: str
    type: ProjectType
    repoUrl: str
    description: str
    tags: list[str]
    accentColor: str
    visual: ProviderVisual
    installStatus: InstallStatus
    runStatus: RunStatus
    requirements: Requirements
    editableConfig: EditableConfig
    compatibility: Compatibility | None = None
    lastBenchmark: Benchmark
    lastRunAt: str
    runtime: ProviderRuntime | None = None
    commands: ProviderCommands | None = None


class ProviderListResponse(BaseModel):
    providers: list[HubProject]
    total: int
    cacheVersion: int


class RunningTask(BaseModel):
    id: str
    projectId: str
    projectName: str
    type: ProjectType
    status: TaskStatus
    startedAt: str
    durationSec: int
    cpuPercent: float
    gpuPercent: float
    ramMb: int
    vramMb: int
    currentStep: str
    progressPercent: int


class ProjectLog(BaseModel):
    id: str
    projectId: str
    source: Literal["install", "runtime", "system"]
    level: LogLevel
    timestamp: str
    message: str
