import { Activity, Cpu, Database, Gauge, HardDrive, Layers3, Server, Thermometer, Zap } from "lucide-react";
import { hardwareSnapshot, hubProjects, runningTasks } from "@/services/mockData";
import { formatMemory } from "@/utils/format";
import { MetricGauge } from "./MetricGauge";
import { RunningTaskRail } from "./RunningTaskRail";

const compatibleProjects = hubProjects.filter((project) => project.compatibility.level !== "red").length;
const activeVramPercent = (hardwareSnapshot.gpu.vramUsedMb / hardwareSnapshot.gpu.vramTotalMb) * 100;
const activeRamPercent = (hardwareSnapshot.ram.usedMb / hardwareSnapshot.ram.totalMb) * 100;

export function HomeDashboard() {
  const freeVramMb = hardwareSnapshot.gpu.vramTotalMb - hardwareSnapshot.gpu.vramUsedMb;
  const freeRamMb = hardwareSnapshot.ram.totalMb - hardwareSnapshot.ram.usedMb;

  return (
    <div className="page-flow">
      <section className="home-hero">
        <div className="hero-copy hero-console">
          <div className="section-kicker">
            <Zap size={16} aria-hidden="true" />
            <span>Local AI command center</span>
          </div>

          <div className="readiness-console" aria-label="Trạng thái sẵn sàng">
            <div className="readiness-number">
              <span>Ready providers</span>
              <strong>{compatibleProjects}</strong>
            </div>
            <div className="readiness-copy">
              <strong>Hardware-aware install hub</strong>
              <div className="readiness-bars" aria-label="Tình trạng tài nguyên">
                <span style={{ "--bar-width": `${100 - activeVramPercent}%` } as React.CSSProperties}>
                  <b>VRAM free</b>
                </span>
                <span style={{ "--bar-width": `${100 - activeRamPercent}%` } as React.CSSProperties}>
                  <b>RAM free</b>
                </span>
                <span style={{ "--bar-width": `${hardwareSnapshot.disk.installPathFreeGb / 4}%` } as React.CSSProperties}>
                  <b>Disk headroom</b>
                </span>
              </div>
            </div>
          </div>

          <div className="hero-signal-grid" aria-label="Tín hiệu hệ thống">
            <SignalTile label="Active tasks" value={`${runningTasks.length}`} tone="cyan" />
            <SignalTile label="VRAM free" value={formatMemory(freeVramMb)} tone="amber" />
            <SignalTile label="RAM free" value={formatMemory(freeRamMb)} tone="green" />
          </div>
        </div>

        <div className="hardware-orbit" aria-label="Tổng quan phần cứng">
          <div className="gpu-core">
            <span>GPU</span>
            <strong>{hardwareSnapshot.gpu.name}</strong>
            <p>{formatMemory(hardwareSnapshot.gpu.vramTotalMb)} VRAM</p>
          </div>
          <MetricGauge label="GPU Load" value={hardwareSnapshot.gpu.usagePercent} detail="Compute active" />
          <MetricGauge label="VRAM" value={activeVramPercent} detail={`${formatMemory(hardwareSnapshot.gpu.vramUsedMb)} used`} tone="amber" />
          <MetricGauge label="Temp" value={hardwareSnapshot.gpu.temperatureC} detail={`${hardwareSnapshot.gpu.temperatureC}°C`} tone="green" />
          <MetricGauge label="Driver" value={82} detail={hardwareSnapshot.gpu.driverVersion} tone="cyan" />
        </div>
      </section>

      <section className="metric-strip" aria-label="Tài nguyên hệ thống">
        <MetricCard
          icon={<Cpu size={18} />}
          label="CPU"
          value={hardwareSnapshot.cpu.name}
          meta={`${hardwareSnapshot.cpu.cores} cores / ${hardwareSnapshot.cpu.usagePercent}%`}
        />
        <MetricCard
          icon={<Database size={18} />}
          label="RAM"
          value={`${formatMemory(hardwareSnapshot.ram.usedMb)} used`}
          meta={`${Math.round(activeRamPercent)}% of ${formatMemory(hardwareSnapshot.ram.totalMb)}`}
        />
        <MetricCard
          icon={<HardDrive size={18} />}
          label="Disk"
          value={`${hardwareSnapshot.disk.installPathFreeGb} GB install free`}
          meta={`${hardwareSnapshot.disk.freeGb} GB total free`}
        />
        <MetricCard
          icon={<Thermometer size={18} />}
          label="Thermal"
          value={`${hardwareSnapshot.cpu.temperatureC}°C CPU / ${hardwareSnapshot.gpu.temperatureC}°C GPU`}
          meta="Stable for long session"
        />
      </section>

      <div className="home-grid">
        <RunningTaskRail tasks={runningTasks} />

        <section className="insight-panel" aria-labelledby="capacity-title">
          <div className="section-kicker">
            <Gauge size={16} aria-hidden="true" />
            <span>Capacity hints</span>
          </div>
          <h2 id="capacity-title">Gợi ý chạy tiếp</h2>
          <div className="hint-stack">
            <article>
              <span className="status-pill status-green">Fit</span>
              <strong>Embedding Foundry có thể install ngay</strong>
              <p>RAM và VRAM đều dư, phù hợp chạy song song với LLM hiện tại.</p>
            </article>
            <article>
              <span className="status-pill status-yellow">Watch</span>
              <strong>Spark LLM Runner nên dùng single-node profile</strong>
              <p>VRAM đủ tối thiểu nhưng gần ngưỡng khuyến nghị.</p>
            </article>
            <article>
              <span className="status-pill status-red">Block</span>
              <strong>NVIDIA Blueprint RAG cần profile nhẹ hơn</strong>
              <p>Reranker/container mặc định vượt ngân sách VRAM hiện tại.</p>
            </article>
          </div>
        </section>

        <section className="activity-panel" aria-labelledby="activity-title">
          <div className="section-kicker">
            <Activity size={16} aria-hidden="true" />
            <span>Recent pulse</span>
          </div>
          <h2 id="activity-title">Hoạt động gần đây</h2>
          <ol className="activity-list">
            <li>
              <span>09:44</span>
              Endpoint LLM mở tại localhost:7860.
            </li>
            <li>
              <span>09:12</span>
              Benchmark Local LLM Studio đạt 72.4 tok/s.
            </li>
            <li>
              <span>20:10</span>
              Blueprint RAG fail vì CUDA out-of-memory.
            </li>
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
