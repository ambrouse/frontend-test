"use client";

import { Activity, Cpu, Database, Gauge, HardDrive, Layers3, Server, Thermometer, Zap } from "lucide-react";
import { useEffect, useState } from "react";
import { fetchHardwareSnapshot, fetchProviderSummary, fetchTasks } from "@/services/apiClient";
import { hardwareSnapshot, hubProjects, runningTasks } from "@/services/mockData";
import type { HardwareSnapshot, ProviderSummary, RunningTask } from "@/services/types";
import { formatMemory } from "@/utils/format";
import { MetricGauge } from "./MetricGauge";
import { RunningTaskRail } from "./RunningTaskRail";

const fallbackSummary: ProviderSummary = {
  total: hubProjects.length,
  ready: hubProjects.filter((project) => project.compatibility.level !== "red").length,
  blocked: hubProjects.filter((project) => project.compatibility.level === "red").length,
  installed: hubProjects.filter((project) => project.installStatus === "installed").length,
  running: hubProjects.filter((project) => project.runStatus === "running").length,
};

export function HomeDashboard() {
  const [hardware, setHardware] = useState<HardwareSnapshot>(hardwareSnapshot);
  const [summary, setSummary] = useState<ProviderSummary>(fallbackSummary);
  const [tasks, setTasks] = useState<RunningTask[]>(runningTasks);
  const freeVramMb = hardware.gpu.vramTotalMb - hardware.gpu.vramUsedMb;
  const freeRamMb = hardware.ram.totalMb - hardware.ram.usedMb;
  const activeVramPercent = (hardware.gpu.vramUsedMb / hardware.gpu.vramTotalMb) * 100;
  const activeRamPercent = (hardware.ram.usedMb / hardware.ram.totalMb) * 100;

  useEffect(() => {
    const controller = new AbortController();
    void fetchHardwareSnapshot({ signal: controller.signal }).then(setHardware).catch(() => {});
    void fetchProviderSummary({ signal: controller.signal }).then(setSummary).catch(() => {});
    void fetchTasks({ signal: controller.signal }).then((response) => setTasks(response.tasks)).catch(() => {});
    return () => controller.abort();
  }, []);

  return (
    <div className="page-flow">
      <section className="home-hero">
        <div className="hero-copy hero-console">
          <div className="section-kicker">
            <Zap size={16} aria-hidden="true" />
            <span>Local AI command center</span>
          </div>

          <div className="readiness-console" aria-label="Readiness status">
            <div className="readiness-number">
              <span>Ready providers</span>
              <strong>{summary.ready}</strong>
            </div>
            <div className="readiness-copy">
              <strong>Hardware-aware install hub</strong>
              <div className="readiness-bars" aria-label="Resource status">
                <span style={{ "--bar-width": `${100 - activeVramPercent}%` } as React.CSSProperties}>
                  <b>VRAM free</b>
                </span>
                <span style={{ "--bar-width": `${100 - activeRamPercent}%` } as React.CSSProperties}>
                  <b>RAM free</b>
                </span>
                <span style={{ "--bar-width": `${hardware.disk.installPathFreeGb / 4}%` } as React.CSSProperties}>
                  <b>Disk headroom</b>
                </span>
              </div>
            </div>
          </div>

          <div className="hero-signal-grid" aria-label="System signals">
            <SignalTile label="Active tasks" value={`${tasks.length}`} tone="cyan" />
            <SignalTile label="VRAM free" value={formatMemory(freeVramMb)} tone="amber" />
            <SignalTile label="RAM free" value={formatMemory(freeRamMb)} tone="green" />
          </div>
        </div>

        <div className="hardware-orbit" aria-label="Hardware overview">
          <div className="gpu-core">
            <span>GPU</span>
            <strong>{hardware.gpu.name}</strong>
            <p>{formatMemory(hardware.gpu.vramTotalMb)} VRAM</p>
          </div>
          <MetricGauge label="GPU Load" value={hardware.gpu.usagePercent} detail="Compute active" />
          <MetricGauge label="VRAM" value={activeVramPercent} detail={`${formatMemory(hardware.gpu.vramUsedMb)} used`} tone="amber" />
          <MetricGauge label="Temp" value={hardware.gpu.temperatureC ?? 0} detail={`${hardware.gpu.temperatureC ?? 0}°C`} tone="green" />
          <MetricGauge label="Driver" value={82} detail={hardware.gpu.driverVersion} tone="cyan" />
        </div>
      </section>

      <section className="metric-strip" aria-label="System resources">
        <MetricCard
          icon={<Cpu size={18} />}
          label="CPU"
          value={hardware.cpu.name}
          meta={`${hardware.cpu.cores} cores / ${hardware.cpu.usagePercent}%`}
        />
        <MetricCard
          icon={<Database size={18} />}
          label="RAM"
          value={`${formatMemory(hardware.ram.usedMb)} used`}
          meta={`${Math.round(activeRamPercent)}% of ${formatMemory(hardware.ram.totalMb)}`}
        />
        <MetricCard
          icon={<HardDrive size={18} />}
          label="Disk"
          value={`${hardware.disk.installPathFreeGb} GB install free`}
          meta={`${hardware.disk.freeGb} GB total free`}
        />
        <MetricCard
          icon={<Thermometer size={18} />}
          label="Thermal"
          value={`${hardware.cpu.temperatureC ?? 0}°C CPU / ${hardware.gpu.temperatureC ?? 0}°C GPU`}
          meta="Stable for long session"
        />
      </section>

      <div className="home-grid">
        <RunningTaskRail tasks={tasks} />

        <section className="insight-panel" aria-labelledby="capacity-title">
          <div className="section-kicker">
            <Gauge size={16} aria-hidden="true" />
            <span>Capacity hints</span>
          </div>
          <h2 id="capacity-title">Next run hints</h2>
          <div className="hint-stack">
            <article>
              <span className="status-pill status-green">Fit</span>
              <strong>{summary.installed} providers installed</strong>
              <p>Backend data is live when available; offline fallback stays non-blocking.</p>
            </article>
            <article>
              <span className="status-pill status-yellow">Watch</span>
              <strong>{summary.running} providers running</strong>
              <p>Long lifecycle actions report through tasks instead of freezing the UI.</p>
            </article>
            <article>
              <span className="status-pill status-red">Block</span>
              <strong>{summary.blocked} providers need attention</strong>
              <p>Hardware warnings are visible, but user actions remain available.</p>
            </article>
          </div>
        </section>

        <section className="activity-panel" aria-labelledby="activity-title">
          <div className="section-kicker">
            <Activity size={16} aria-hidden="true" />
            <span>Recent pulse</span>
          </div>
          <h2 id="activity-title">Runtime activity</h2>
          <ol className="activity-list">
            {tasks.slice(0, 3).map((task) => (
              <li key={task.id}>
                <span>{task.status}</span>
                {task.projectName}: {task.currentStep}
              </li>
            ))}
            {tasks.length === 0 ? (
              <li>
                <span>idle</span>
                No active backend tasks.
              </li>
            ) : null}
          </ol>
        </section>
      </div>
    </div>
  );
}

function SignalTile({
  label,
  value,
  tone,
}: {
  label: string;
  value: string;
  tone: "cyan" | "amber" | "green";
}) {
  const icons = {
    cyan: <Server size={17} />,
    amber: <Layers3 size={17} />,
    green: <Gauge size={17} />,
  };

  return (
    <article className={`signal-tile signal-${tone}`}>
      <span aria-hidden="true">{icons[tone]}</span>
      <div>
        <p>{label}</p>
        <strong>{value}</strong>
      </div>
    </article>
  );
}

function MetricCard({
  icon,
  label,
  value,
  meta,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  meta: string;
}) {
  return (
    <article className="metric-card">
      <div className="metric-icon" aria-hidden="true">
        {icon}
      </div>
      <span>{label}</span>
      <strong>{value}</strong>
      <p>{meta}</p>
    </article>
  );
}
