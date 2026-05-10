"use client";

import clsx from "clsx";
import { CheckCircle2, Copy, Download, Play, RotateCcw, Square, Trash2 } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import {
  fetchHardwareSnapshot,
  fetchProviderConfig,
  fetchProviderDetail,
  fetchProviderLogs,
  fetchProviderMetrics,
  fetchProviderStatus,
  providerAction,
} from "@/services/apiClient";
import { emptyHardwareSnapshot } from "@/services/emptyState";
import type { HardwareSnapshot, HubProject, LogLevel, ProjectLog, ProviderConfig, ProviderMetrics, ProviderStatus } from "@/services/types";
import { formatMemory, formatProjectType } from "@/utils/format";
import { CompatibilityPing } from "./CompatibilityPing";

const logLevels: Array<LogLevel | "all"> = ["all", "info", "warn", "error", "debug"];

export function ProjectDetailView({ projectId, project }: { projectId: string; project?: HubProject }) {
  const [activeLogLevel, setActiveLogLevel] = useState<LogLevel | "all">("all");
  const [projectData, setProjectData] = useState<HubProject | null>(project ?? null);
  const [hardware, setHardware] = useState<HardwareSnapshot>(emptyHardwareSnapshot);
  const [status, setStatus] = useState<ProviderStatus | null>(null);
  const [metrics, setMetrics] = useState<ProviderMetrics | null>(null);
  const [config, setConfig] = useState<ProviderConfig | null>(null);
  const [logs, setLogs] = useState<ProjectLog[]>([]);
  const [pendingAction, setPendingAction] = useState<string | null>(null);
  const [actionMessage, setActionMessage] = useState("");

  const visibleLogs = useMemo(() => {
    return activeLogLevel === "all" ? logs : logs.filter((log) => log.level === activeLogLevel);
  }, [activeLogLevel, logs]);

  const availableRamMb = Math.max(0, hardware.ram.totalMb - hardware.ram.usedMb);
  const availableVramMb = Math.max(0, hardware.gpu.vramTotalMb - hardware.gpu.vramUsedMb);
  const effectiveConfig = config ?? (projectData ? { ...projectData.editableConfig, env: {}, warnings: [] } : null);
  const headlineMetric = metrics?.benchmark?.headlineMetric?.toString() ?? projectData?.lastBenchmark.headlineMetric ?? "loading";
  const secondaryMetric = metrics?.benchmark?.secondaryMetric?.toString() ?? projectData?.lastBenchmark.secondaryMetric ?? "waiting for backend";
  const runState = status?.state ?? projectData?.runStatus ?? "unknown";

  useEffect(() => {
    if (!projectData) return;
    document.documentElement.style.setProperty("--page-accent", projectData.visual.ambient);
    document.documentElement.style.setProperty("--page-accent-soft", projectData.visual.ambientSoft);
  }, [projectData]);

  useEffect(() => {
    const controller = new AbortController();
    const load = () => {
      void fetchProviderDetail(projectId, { signal: controller.signal }).then(setProjectData).catch(() => {});
      void fetchHardwareSnapshot({ signal: controller.signal }).then(setHardware).catch(() => {});
      void fetchProviderStatus(projectId, { signal: controller.signal }).then(setStatus).catch(() => {});
      void fetchProviderMetrics(projectId, { signal: controller.signal }).then(setMetrics).catch(() => {});
      void fetchProviderConfig(projectId, { signal: controller.signal }).then(setConfig).catch(() => {});
      void fetchProviderLogs(projectId, { signal: controller.signal, level: activeLogLevel }).then((response) => setLogs(response.logs)).catch(() => {});
    };
    load();
    const interval = window.setInterval(load, 3000);
    return () => {
      controller.abort();
      window.clearInterval(interval);
    };
  }, [activeLogLevel, projectId]);

  const handleAction = async (action: "install" | "run" | "stop" | "delete") => {
    setPendingAction(action);
    setActionMessage("");
    try {
      const response = await providerAction(projectId, action, { force: true });
      setActionMessage(`Task ${response.taskId} queued`);
      const [nextStatus, nextLogs] = await Promise.all([
        fetchProviderStatus(projectId, { timeoutMs: 1500 }).catch(() => null),
        fetchProviderLogs(projectId, { timeoutMs: 1500, level: activeLogLevel }).catch(() => null),
      ]);
      if (nextStatus) setStatus(nextStatus);
      if (nextLogs) setLogs(nextLogs.logs);
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : "Action failed");
    } finally {
      setPendingAction(null);
    }
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
            "--project-image": `url(${projectData.visual.imageUrl})`,
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
          <button className="primary-action" type="button" onClick={() => handleAction(runState === "running" ? "stop" : "run")} disabled={pendingAction !== null}>
            {runState === "running" ? <Square size={17} aria-hidden="true" /> : <Play size={17} aria-hidden="true" />}
            {pendingAction === "run" || pendingAction === "stop" ? "Working" : runState === "running" ? "Stop" : "Run"}
          </button>
          <button className="ghost-action" type="button" onClick={() => handleAction("install")} disabled={pendingAction !== null}>
            <RotateCcw size={17} aria-hidden="true" />
            {pendingAction === "install" ? "Installing" : "Install"}
          </button>
          <button className="danger-action" type="button" onClick={() => handleAction("delete")} disabled={pendingAction !== null}>
            <Trash2 size={17} aria-hidden="true" />
            {pendingAction === "delete" ? "Deleting" : "Delete"}
          </button>
        </div>
      </section>

      {actionMessage ? <p className="detail-action-message">{actionMessage}</p> : null}

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
      </div>

      <section className="logs-panel" aria-labelledby="logs-title">
        <div className="logs-heading">
          <div>
            <h2 id="logs-title">Logs</h2>
            <p>Install/runtime/system output from backend provider runtime.</p>
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

        <div className="terminal-frame">
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
      </section>
    </div>
  );
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
