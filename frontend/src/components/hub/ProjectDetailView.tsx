"use client";

import clsx from "clsx";
import { CheckCircle2, ChevronLeft, ChevronRight, Copy, Download, Loader2, Play, RotateCcw, Square, Trash2 } from "lucide-react";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  fetchHardwareSnapshot,
  fetchActiveTasks,
  fetchProviderConfig,
  fetchProviderDetail,
  fetchProviderLogs,
  fetchProviderMetrics,
  fetchProviderStatus,
  providerAction,
  readSelectedProvider,
  resolveApiAssetUrl,
} from "@/services/apiClient";
import { emptyHardwareSnapshot } from "@/services/emptyState";
import type { HardwareSnapshot, HubProject, LogLevel, ProjectLog, ProviderConfig, ProviderMetrics, ProviderStatus, RunningTask } from "@/services/types";
import { formatMemory, formatProjectType } from "@/utils/format";
import { CompatibilityPing } from "./CompatibilityPing";

const logLevels: Array<LogLevel | "all"> = ["all", "info", "warn", "error", "debug"];
type ProviderLifecycleAction = "install" | "run" | "stop" | "delete";
type LogPanelTab = "progress" | "details";

const actionLabels: Record<ProviderLifecycleAction, { idle: string; active: string }> = {
  install: { idle: "Install", active: "Installing" },
  run: { idle: "Run", active: "Running" },
  stop: { idle: "Stop", active: "Stopping" },
  delete: { idle: "Delete", active: "Deleting" },
};

export function ProjectDetailView({ projectId, project }: { projectId: string; project?: HubProject }) {
  const [activeLogTab, setActiveLogTab] = useState<LogPanelTab>("progress");
  const [activeLogLevel, setActiveLogLevel] = useState<LogLevel | "all">("all");
  const [activeVisualIndex, setActiveVisualIndex] = useState(0);
  const [projectData, setProjectData] = useState<HubProject | null>(() => project ?? readSelectedProvider(projectId));
  const [hardware, setHardware] = useState<HardwareSnapshot>(emptyHardwareSnapshot);
  const [status, setStatus] = useState<ProviderStatus | null>(null);
  const [metrics, setMetrics] = useState<ProviderMetrics | null>(null);
  const [config, setConfig] = useState<ProviderConfig | null>(null);
  const [logs, setLogs] = useState<ProjectLog[]>([]);
  const [activeTasks, setActiveTasks] = useState<RunningTask[]>([]);
  const [pendingAction, setPendingAction] = useState<ProviderLifecycleAction | null>(null);
  const [queuedAction, setQueuedAction] = useState<{ taskId: string; action: ProviderLifecycleAction; queuedAt: number } | null>(null);
  const [actionMessage, setActionMessage] = useState("");
  const [isLogFeedActive, setIsLogFeedActive] = useState(false);
  const [lastLogChangeAt, setLastLogChangeAt] = useState<number>(0);
  const terminalRef = useRef<HTMLDivElement | null>(null);
  const latestLogFingerprintRef = useRef("");

  const visibleLogs = useMemo(() => {
    return activeLogLevel === "all" ? logs : logs.filter((log) => log.level === activeLogLevel);
  }, [activeLogLevel, logs]);

  const availableRamMb = Math.max(0, hardware.ram.totalMb - hardware.ram.usedMb);
  const availableVramMb = Math.max(0, hardware.gpu.vramTotalMb - hardware.gpu.vramUsedMb);
  const effectiveConfig = config ?? (projectData ? { ...projectData.editableConfig, env: {}, warnings: [] } : null);
  const headlineMetric = metrics?.benchmark?.headlineMetric?.toString() ?? projectData?.lastBenchmark.headlineMetric ?? "loading";
  const secondaryMetric = metrics?.benchmark?.secondaryMetric?.toString() ?? projectData?.lastBenchmark.secondaryMetric ?? "waiting for backend";
  const runState = status?.state ?? projectData?.runStatus ?? "unknown";
  const providerTask = useMemo(() => {
    return activeTasks.find((task) => task.projectId === projectId) ?? null;
  }, [activeTasks, projectId]);
  const activeAction = queuedAction?.action ?? pendingAction ?? taskStatusToAction(providerTask?.status) ?? (runState === "running" ? "stop" : "run");
  const isLifecycleBusy = pendingAction !== null || queuedAction !== null || providerTask !== null;
  const lifecycleProgress = providerTask?.progressPercent ?? status?.progressPercent ?? (isLifecycleBusy ? 8 : 0);
  const lifecycleStep =
    providerTask?.currentStep ??
    (queuedAction ? `Task ${queuedAction.taskId} queued` : pendingAction ? "Queuing provider action" : status?.currentStep ?? "Idle");
  const visualImages = useMemo(() => {
    if (!projectData) return [];
    const gallery = projectData.visual.gallery?.filter(Boolean) ?? [];
    return gallery.length > 0 ? gallery : [projectData.visual.imageUrl];
  }, [projectData]);
  const activeVisualImage = resolveApiAssetUrl(visualImages[activeVisualIndex] ?? projectData?.visual.imageUrl ?? "");
  const progressEvents = useMemo(() => {
    const events: Array<{ id: string; label: string; message: string; tone: "active" | "info" | "error" }> = [];
    if (providerTask) {
      events.push({
        id: `task-${providerTask.id}`,
        label: `${providerTask.status} ${providerTask.progressPercent}%`,
        message: providerTask.currentStep,
        tone: providerTask.status === "failed" ? "error" : "active",
      });
    }
    if (queuedAction) {
      events.push({
        id: `queued-${queuedAction.taskId}`,
        label: actionLabels[queuedAction.action].active,
        message: `Task ${queuedAction.taskId} queued`,
        tone: "active",
      });
    }
    if (status) {
      events.push({
        id: `status-${status.state}-${status.currentStep}`,
        label: status.state,
        message: status.currentStep,
        tone: status.health?.level === "error" ? "error" : "info",
      });
    }
    if (actionMessage) {
      events.push({ id: "action-message", label: "message", message: actionMessage, tone: "info" });
    }

    for (const log of logs.slice(-8).reverse()) {
      events.push({
        id: log.id,
        label: log.source,
        message: log.message,
        tone: log.level === "error" ? "error" : "info",
      });
    }

    return events;
  }, [actionMessage, logs, providerTask, queuedAction, status]);

  useEffect(() => {
    if (!projectData) return;
    document.documentElement.style.setProperty("--page-accent", projectData.visual.ambient);
    document.documentElement.style.setProperty("--page-accent-soft", projectData.visual.ambientSoft);
  }, [projectData]);

  useEffect(() => {
    setActiveVisualIndex(0);
  }, [projectData?.id, projectData?.visual.imageUrl, projectData?.visual.gallery?.join("|")]);

  useEffect(() => {
    if (visualImages.length <= 1) {
      return;
    }
    const interval = window.setInterval(() => {
      setActiveVisualIndex((current) => (current + 1) % visualImages.length);
    }, 5200);
    return () => window.clearInterval(interval);
  }, [visualImages.length]);

  useEffect(() => {
    const controller = new AbortController();
    const load = () => {
      void fetchProviderDetail(projectId, { signal: controller.signal }).then(setProjectData).catch(() => {});
      void fetchHardwareSnapshot({ signal: controller.signal }).then(setHardware).catch(() => {});
      void fetchProviderStatus(projectId, { signal: controller.signal }).then(setStatus).catch(() => {});
      void fetchProviderMetrics(projectId, { signal: controller.signal }).then(setMetrics).catch(() => {});
      void fetchProviderConfig(projectId, { signal: controller.signal }).then(setConfig).catch(() => {});
      void fetchProviderLogs(projectId, { signal: controller.signal }).then((response) => setLogs(response.logs)).catch(() => {});
      void fetchActiveTasks({ signal: controller.signal, timeoutMs: 1200 }).then((response) => setActiveTasks(response.tasks)).catch(() => {});
    };
    load();
    const interval = window.setInterval(load, 3000);
    return () => {
      controller.abort();
      window.clearInterval(interval);
    };
  }, [projectId]);

  useEffect(() => {
    const controller = new AbortController();
    const pollTasks = () => {
      void fetchActiveTasks({ signal: controller.signal, timeoutMs: 1200 })
        .then((response) => setActiveTasks(response.tasks))
        .catch(() => {});
    };

    pollTasks();
    const interval = window.setInterval(pollTasks, isLifecycleBusy ? 900 : 2500);
    return () => {
      controller.abort();
      window.clearInterval(interval);
    };
  }, [isLifecycleBusy]);

  useEffect(() => {
    if (!queuedAction) {
      return;
    }
    if (activeTasks.some((task) => task.id === queuedAction.taskId)) {
      return;
    }
    if (Date.now() - queuedAction.queuedAt < 1800) {
      return;
    }

    setQueuedAction(null);
    void fetchProviderDetail(projectId, { timeoutMs: 1500 }).then(setProjectData).catch(() => {});
    void fetchProviderStatus(projectId, { timeoutMs: 1500 }).then(setStatus).catch(() => {});
    void fetchProviderLogs(projectId, { timeoutMs: 1500 }).then((response) => setLogs(response.logs)).catch(() => {});
  }, [activeTasks, projectId, queuedAction]);

  useEffect(() => {
    const latestLog = logs.at(-1);
    const fingerprint = latestLog ? `${logs.length}:${latestLog.timestamp}:${latestLog.level}:${latestLog.message}` : "empty";
    if (fingerprint === latestLogFingerprintRef.current) {
      return;
    }

    latestLogFingerprintRef.current = fingerprint;
    setLastLogChangeAt(Date.now());
    setIsLogFeedActive(Boolean(latestLog));
  }, [logs]);

  useEffect(() => {
    if (!isLogFeedActive) {
      return;
    }

    const timer = window.setInterval(() => {
      if (Date.now() - lastLogChangeAt >= 6500) {
        setIsLogFeedActive(false);
      }
    }, 800);

    return () => window.clearInterval(timer);
  }, [isLogFeedActive, lastLogChangeAt]);

  useEffect(() => {
    if (!isLogFeedActive) {
      return;
    }

    const frame = terminalRef.current;
    if (!frame) {
      return;
    }
    frame.scrollTop = frame.scrollHeight;
  }, [isLogFeedActive, logs]);

  const handleAction = async (action: ProviderLifecycleAction) => {
    setPendingAction(action);
    setQueuedAction(null);
    setActionMessage("");
    try {
      const response = await providerAction(projectId, action, { force: true });
      const nextMessage = response.warnings[0] ?? `Task ${response.taskId} queued`;
      setActionMessage(nextMessage);
      setQueuedAction({ taskId: response.taskId, action, queuedAt: Date.now() });
      const [nextStatus, nextLogs] = await Promise.all([
        fetchProviderStatus(projectId, { timeoutMs: 1500 }).catch(() => null),
        fetchProviderLogs(projectId, { timeoutMs: 1500 }).catch(() => null),
        fetchActiveTasks({ timeoutMs: 1500 }).then((response) => setActiveTasks(response.tasks)).catch(() => null),
      ]);
      if (nextStatus) setStatus(nextStatus);
      if (nextLogs) setLogs(nextLogs.logs);
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : "Action failed");
    } finally {
      setPendingAction(null);
    }
  };

  const handleVisualStep = (direction: -1 | 1) => {
    setActiveVisualIndex((current) => (current + direction + visualImages.length) % visualImages.length);
  };

  if (!projectData || !effectiveConfig) {
    return (
      <div className="page-flow detail-flow">
        <section className="detail-hero detail-hero-loading">
          <div>
            <h1>Loading provider</h1>
            <div className="detail-meta-strip" aria-label="Project information">
              <span>{projectId}</span>
              <span>backend</span>
              <span>{runState}</span>
            </div>
          </div>
        </section>
      </div>
    );
  }

  return (
    <div className="page-flow detail-flow">
      <section
        className="detail-hero"
        style={
          {
            "--project-accent": projectData.accentColor,
            "--project-image": `url(${activeVisualImage})`,
            "--project-focus": projectData.visual.focus,
          } as React.CSSProperties
        }
      >
        <div>
          <h1>{projectData.name}</h1>
          <div className="detail-meta-strip" aria-label="Project information">
            <span>{formatProjectType(projectData.type)}</span>
            <span>{projectData.installStatus.replace("_", " ")}</span>
            <span>{runState}</span>
            <span>{headlineMetric}</span>
          </div>
        </div>

        <div className="detail-actions">
          <CompatibilityPing level={projectData.compatibility.level} reasons={projectData.compatibility.reasons} />
          <button className="primary-action" type="button" onClick={() => handleAction(runState === "running" ? "stop" : "run")} disabled={isLifecycleBusy}>
            {isLifecycleBusy && (activeAction === "run" || activeAction === "stop") ? (
              <Loader2 className="spin-icon" size={17} aria-hidden="true" />
            ) : runState === "running" ? (
              <Square size={17} aria-hidden="true" />
            ) : (
              <Play size={17} aria-hidden="true" />
            )}
            {isLifecycleBusy && (activeAction === "run" || activeAction === "stop")
              ? actionLabels[activeAction].active
              : runState === "running"
                ? "Stop"
                : "Run"}
          </button>
          <button className="ghost-action" type="button" onClick={() => handleAction("install")} disabled={isLifecycleBusy}>
            {isLifecycleBusy && activeAction === "install" ? <Loader2 className="spin-icon" size={17} aria-hidden="true" /> : <RotateCcw size={17} aria-hidden="true" />}
            {isLifecycleBusy && activeAction === "install" ? actionLabels.install.active : actionLabels.install.idle}
          </button>
          <button className="danger-action" type="button" onClick={() => handleAction("delete")} disabled={isLifecycleBusy}>
            {isLifecycleBusy && activeAction === "delete" ? <Loader2 className="spin-icon" size={17} aria-hidden="true" /> : <Trash2 size={17} aria-hidden="true" />}
            {isLifecycleBusy && activeAction === "delete" ? actionLabels.delete.active : actionLabels.delete.idle}
          </button>
        </div>

        {visualImages.length > 1 ? (
          <div className="detail-gallery-controls" aria-label="Provider images">
            <button type="button" onClick={() => handleVisualStep(-1)} aria-label="Previous image">
              <ChevronLeft size={18} aria-hidden="true" />
            </button>
            <div className="detail-gallery-dots" aria-hidden="true">
              {visualImages.map((image, index) => (
                <span key={`${image}-${index}`} className={index === activeVisualIndex ? "is-active" : undefined} />
              ))}
            </div>
            <button type="button" onClick={() => handleVisualStep(1)} aria-label="Next image">
              <ChevronRight size={18} aria-hidden="true" />
            </button>
          </div>
        ) : null}
      </section>

      {isLifecycleBusy ? (
        <section className="lifecycle-progress" aria-live="polite" aria-label="Provider lifecycle progress">
          <div>
            <span>{actionLabels[activeAction].active}</span>
            <strong>{lifecycleStep}</strong>
          </div>
          <div className="progress-track" aria-label={`Progress ${lifecycleProgress}%`}>
            <span style={{ width: `${Math.min(Math.max(lifecycleProgress, 8), 100)}%` }} />
          </div>
        </section>
      ) : null}

      {actionMessage ? <p className="detail-action-message">{actionMessage}</p> : null}
      <p className="detail-delete-note">Delete chi xoa runtime/deploy trong `deploy/{projectData.id}`, khong xoa source provider trong `providers/`.</p>

      <div className="detail-grid">
        <section className="fit-panel" aria-labelledby="fit-title">
          <h2 id="fit-title">Machine fit</h2>
          <RequirementRow label="CPU cores" current={`${hardware.cpu.cores}`} required={`${projectData.requirements.minimum.cpuCores}`} isReady={hardware.cpu.cores >= projectData.requirements.minimum.cpuCores} />
          <RequirementRow label="RAM free" current={formatMemory(availableRamMb)} required={formatMemory(projectData.requirements.minimum.ramMb)} isReady={availableRamMb >= projectData.requirements.minimum.ramMb} />
          <RequirementRow label="VRAM free" current={formatMemory(availableVramMb)} required={formatMemory(projectData.requirements.minimum.vramMb)} isReady={availableVramMb >= projectData.requirements.minimum.vramMb} />
          <RequirementRow label="Disk free" current={`${hardware.disk.installPathFreeGb} GB`} required={`${projectData.requirements.minimum.diskGb} GB`} isReady={hardware.disk.installPathFreeGb >= projectData.requirements.minimum.diskGb} />
        </section>

        <section className="benchmark-panel" aria-labelledby="benchmark-title">
          <h2 id="benchmark-title">Last benchmark</h2>
          <div className="benchmark-main">
            <span>{headlineMetric}</span>
            <strong>{secondaryMetric}</strong>
          </div>
          <div className="benchmark-grid">
            <MetricTile label="VRAM peak" value={formatMemory(projectData.lastBenchmark.vramPeakMb)} />
            <MetricTile label="Profile" value={effectiveConfig.profile} />
            <MetricTile label="Port" value={`${effectiveConfig.port}`} />
            <MetricTile label="Branch" value={effectiveConfig.branch} />
          </div>
        </section>

        <section className="config-panel" aria-labelledby="config-title">
          <h2 id="config-title">Quick config</h2>
          <label>
            Profile
            <input value={effectiveConfig.profile} readOnly />
          </label>
          <label>
            Branch
            <input value={effectiveConfig.branch} readOnly />
          </label>
          <label className={effectiveConfig.warnings.length ? "config-warning" : undefined}>
            Port
            <input value={effectiveConfig.port} readOnly />
          </label>
          <label>
            Install path
            <input value={effectiveConfig.installDirectory} readOnly />
          </label>
        </section>

        {projectData.environment ? (
          <section className="environment-panel" aria-labelledby="environment-title">
            <div className="environment-heading">
              <h2 id="environment-title">Runtime requirements</h2>
              {projectData.environment.readiness ? (
                <CompatibilityPing
                  level={projectData.environment.readiness.level}
                  reasons={projectData.environment.readiness.reasons}
                />
              ) : null}
            </div>
            <div className="environment-summary">
              <MetricTile label="This OS" value={projectData.environment.readiness?.os ?? "unknown"} />
              <MetricTile label="Architecture" value={projectData.environment.readiness?.architecture ?? "unknown"} />
            </div>
            <div className="tool-list" aria-label="Required tools">
              {projectData.environment.requiredTools.map((tool) => (
                <div key={tool.id} className={clsx("tool-row", tool.available ? "tool-ready" : "tool-missing")}>
                  <span>{tool.available ? "Ready" : tool.required ? "Missing" : "Optional"}</span>
                  <strong>{tool.label}</strong>
                  <p>{tool.version ?? tool.installHint ?? tool.command}</p>
                </div>
              ))}
            </div>
            <div className="environment-chip-row" aria-label="Frameworks">
              {projectData.environment.frameworks.slice(0, 8).map((framework) => (
                <span key={framework}>{framework}</span>
              ))}
            </div>
            <div className="runtime-mode-grid" aria-label="Runtime modes">
              {projectData.environment.runtimeModes.map((mode) => (
                <article key={mode.id}>
                  <strong>{mode.label}</strong>
                  <p>{mode.description}</p>
                  <span>{mode.requiresGpu ? "GPU mode" : "API mode"}</span>
                  {mode.requiresNvidiaKey ? <span>NVIDIA key</span> : null}
                </article>
              ))}
            </div>
          </section>
        ) : null}
      </div>

      <section className="logs-panel" aria-labelledby="logs-title">
        <div className="logs-heading">
          <div>
            <h2 id="logs-title">Provider activity</h2>
            <p>Progress stays readable while detailed logs keep the full provider output.</p>
          </div>
          <div className="log-actions">
            <button type="button" aria-label="Copy logs">
              <Copy size={16} aria-hidden="true" />
            </button>
            <button type="button" aria-label="Export logs">
              <Download size={16} aria-hidden="true" />
            </button>
          </div>
        </div>

        <div className="log-tabs" role="tablist" aria-label="Provider log views">
          <button
            type="button"
            role="tab"
            aria-selected={activeLogTab === "progress"}
            className={activeLogTab === "progress" ? "is-active" : undefined}
            onClick={() => setActiveLogTab("progress")}
          >
            Progress
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={activeLogTab === "details"}
            className={activeLogTab === "details" ? "is-active" : undefined}
            onClick={() => setActiveLogTab("details")}
          >
            Detailed logs
          </button>
        </div>

        {activeLogTab === "details" ? (
          <div className="log-filter" aria-label="Log filter">
            {logLevels.map((level) => (
              <button
                key={level}
                type="button"
                className={activeLogLevel === level ? "is-active" : undefined}
                onClick={() => setActiveLogLevel(level)}
              >
                {level}
              </button>
            ))}
          </div>
        ) : null}

        {activeLogTab === "progress" ? (
          <div className="progress-feed" role="tabpanel" aria-label="Provider progress">
            {progressEvents.length === 0 ? (
              <p className="empty-log">No provider progress yet.</p>
            ) : (
              progressEvents.map((event) => (
                <div key={event.id} className={clsx("progress-event", `progress-event-${event.tone}`)}>
                  <span>{event.label}</span>
                  <p>{event.message}</p>
                </div>
              ))
            )}
          </div>
        ) : (
          <>
            <div
              className="terminal-frame"
              ref={terminalRef}
              role="tabpanel"
              aria-label="Detailed provider logs"
              onScroll={() => {
                const frame = terminalRef.current;
                if (!frame || !isLogFeedActive) {
                  return;
                }
                const isNearBottom = frame.scrollHeight - frame.scrollTop - frame.clientHeight < 10;
                if (!isNearBottom) {
                  frame.scrollTop = frame.scrollHeight;
                }
              }}
            >
              {visibleLogs.length === 0 ? (
                <p className="empty-log">No logs for this filter.</p>
              ) : (
                visibleLogs.map((log) => (
                  <div key={log.id} className={clsx("log-line", `log-${log.level}`)}>
                    <span>{new Date(log.timestamp).toLocaleTimeString("vi-VN")}</span>
                    <strong>{log.level}</strong>
                    <p>{log.message}</p>
                  </div>
                ))
              )}
            </div>
            <p className="log-follow-state">{isLogFeedActive ? "Live logs: auto-follow enabled." : "Logs idle: you can scroll manually."}</p>
          </>
        )}

        {activeLogTab === "details" ? null : (
          <p className="log-follow-state">{isLifecycleBusy ? "Progress is following the active provider task." : "Progress is idle."}</p>
        )}
      </section>
    </div>
  );
}

function taskStatusToAction(status?: RunningTask["status"]): ProviderLifecycleAction | null {
  if (!status) return null;
  if (status === "installing") return "install";
  if (status === "running") return "run";
  if (status === "stopping") return "stop";
  if (status === "deleting") return "delete";
  return null;
}

function RequirementRow({
  label,
  current,
  required,
  isReady,
}: {
  label: string;
  current: string;
  required: string;
  isReady: boolean;
}) {
  return (
    <div className="requirement-fit-row">
      <span className={isReady ? "fit-ready" : "fit-blocked"}>
        <CheckCircle2 size={16} aria-hidden="true" />
      </span>
      <strong>{label}</strong>
      <p>{current}</p>
      <small>min {required}</small>
    </div>
  );
}

function MetricTile({ label, value }: { label: string; value: string }) {
  return (
    <div className="metric-tile">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}
