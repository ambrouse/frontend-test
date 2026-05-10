"use client";

import clsx from "clsx";
import { CheckCircle2, Copy, Download, Play, RotateCcw, Square, Trash2 } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { getProjectLogs, hardwareSnapshot } from "@/services/mockData";
import type { HubProject, LogLevel } from "@/services/types";
import { formatMemory, formatProjectType } from "@/utils/format";
import { CompatibilityPing } from "./CompatibilityPing";

const logLevels: Array<LogLevel | "all"> = ["all", "info", "warn", "error", "debug"];

export function ProjectDetailView({ project }: { project: HubProject }) {
  const [activeLogLevel, setActiveLogLevel] = useState<LogLevel | "all">("all");
  const [actionState, setActionState] = useState(project.runStatus);
  const logs = getProjectLogs(project.id);

  const visibleLogs = useMemo(() => {
    return activeLogLevel === "all" ? logs : logs.filter((log) => log.level === activeLogLevel);
  }, [activeLogLevel, logs]);

  const availableRamMb = hardwareSnapshot.ram.totalMb - hardwareSnapshot.ram.usedMb;
  const availableVramMb = hardwareSnapshot.gpu.vramTotalMb - hardwareSnapshot.gpu.vramUsedMb;

  useEffect(() => {
    document.documentElement.style.setProperty("--page-accent", project.visual.ambient);
    document.documentElement.style.setProperty("--page-accent-soft", project.visual.ambientSoft);
  }, [project]);

  const handleRunToggle = () => {
    setActionState((currentState) => (currentState === "running" ? "stopped" : "running"));
  };

  return (
    <div className="page-flow detail-flow">
      <section
        className="detail-hero"
        style={
          {
            "--project-accent": project.accentColor,
            "--project-image": `url(${project.visual.imageUrl})`,
            "--project-focus": project.visual.focus,
          } as React.CSSProperties
        }
      >
        <div>
          <h1>{project.name}</h1>
          <div className="detail-meta-strip" aria-label="Thông tin project">
            <span>{formatProjectType(project.type)}</span>
            <span>{project.installStatus.replace("_", " ")}</span>
            <span>{project.runStatus}</span>
            <span>{project.lastBenchmark.headlineMetric}</span>
          </div>
        </div>

        <div className="detail-actions">
          <CompatibilityPing level={project.compatibility.level} reasons={project.compatibility.reasons} />
          <button className="primary-action" type="button" onClick={handleRunToggle}>
            {actionState === "running" ? <Square size={17} aria-hidden="true" /> : <Play size={17} aria-hidden="true" />}
            {actionState === "running" ? "Stop" : "Run"}
          </button>
          <button className="ghost-action" type="button">
            <RotateCcw size={17} aria-hidden="true" />
            Install
          </button>
          <button className="danger-action" type="button">
            <Trash2 size={17} aria-hidden="true" />
            Delete
          </button>
        </div>
      </section>

      <div className="detail-grid">
        <section className="fit-panel" aria-labelledby="fit-title">
          <h2 id="fit-title">Machine fit</h2>
          <RequirementRow label="CPU cores" current={`${hardwareSnapshot.cpu.cores}`} required={`${project.requirements.minimum.cpuCores}`} isReady={hardwareSnapshot.cpu.cores >= project.requirements.minimum.cpuCores} />
          <RequirementRow label="RAM free" current={formatMemory(availableRamMb)} required={formatMemory(project.requirements.minimum.ramMb)} isReady={availableRamMb >= project.requirements.minimum.ramMb} />
          <RequirementRow label="VRAM free" current={formatMemory(availableVramMb)} required={formatMemory(project.requirements.minimum.vramMb)} isReady={availableVramMb >= project.requirements.minimum.vramMb} />
          <RequirementRow label="Disk free" current={`${hardwareSnapshot.disk.installPathFreeGb} GB`} required={`${project.requirements.minimum.diskGb} GB`} isReady={hardwareSnapshot.disk.installPathFreeGb >= project.requirements.minimum.diskGb} />
        </section>

        <section className="benchmark-panel" aria-labelledby="benchmark-title">
          <h2 id="benchmark-title">Last benchmark</h2>
          <div className="benchmark-main">
            <span>{project.lastBenchmark.headlineMetric}</span>
            <strong>{project.lastBenchmark.secondaryMetric}</strong>
          </div>
          <div className="benchmark-grid">
            <MetricTile label="VRAM peak" value={formatMemory(project.lastBenchmark.vramPeakMb)} />
            <MetricTile label="Profile" value={project.editableConfig.profile} />
            <MetricTile label="Port" value={`${project.editableConfig.port}`} />
            <MetricTile label="Branch" value={project.editableConfig.branch} />
          </div>
        </section>

        <section className="config-panel" aria-labelledby="config-title">
          <h2 id="config-title">Quick config</h2>
          <label>
            Profile
            <input value={project.editableConfig.profile} readOnly />
          </label>
          <label>
            Branch
            <input value={project.editableConfig.branch} readOnly />
          </label>
          <label>
            Install path
            <input value={project.editableConfig.installDirectory} readOnly />
          </label>
        </section>
      </div>

      <section className="logs-panel" aria-labelledby="logs-title">
        <div className="logs-heading">
          <div>
            <h2 id="logs-title">Logs</h2>
            <p>Install/runtime/system output cho lần chạy gần nhất.</p>
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

        <div className="log-filter" aria-label="Lọc logs">
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
            <p className="empty-log">Không có log ở filter này.</p>
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
