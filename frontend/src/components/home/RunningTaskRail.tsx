import { Clock3 } from "lucide-react";
import type { RunningTask } from "@/services/types";
import { formatDuration, formatMemory, formatProjectType } from "@/utils/format";

export function RunningTaskRail({ tasks }: { tasks: RunningTask[] }) {
  return (
    <section className="task-rail" aria-labelledby="running-tasks-title">
      <div className="section-kicker sougen-kicker">
        <Clock3 size={16} aria-hidden="true" />
        <span>Runtime rail</span>
      </div>
      <h2 id="running-tasks-title">Live tasks</h2>

      <div className="task-list">
        {tasks.map((task) => (
          <article key={task.id} className="task-item">
            <div className="task-line" aria-hidden="true">
              <span />
            </div>
            <div className="task-body">
              <div className="task-heading">
                <span>{formatProjectType(task.type)}</span>
                <strong>{task.projectName}</strong>
              </div>
              <p>{task.currentStep}</p>
              <div className="task-metrics">
                <span>{formatDuration(task.durationSec)}</span>
                <span>CPU {task.cpuPercent}%</span>
                <span>GPU {task.gpuPercent}%</span>
                <span>RAM {formatMemory(task.ramMb)}</span>
                <span>VRAM {formatMemory(task.vramMb)}</span>
              </div>
              <div className="progress-track" aria-label={`Progress ${task.progressPercent}%`}>
                <span style={{ width: `${task.progressPercent}%` }} />
              </div>
            </div>
          </article>
        ))}
        {tasks.length === 0 ? (
          <article className="task-item is-empty">
            <div className="task-line" aria-hidden="true">
              <span />
            </div>
            <div className="task-body">
              <div className="task-heading">
                <span>Idle</span>
                <strong>No active tasks</strong>
              </div>
              <p>Provider installs and runtime jobs will appear here as soon as the backend starts one.</p>
            </div>
          </article>
        ) : null}
      </div>
    </section>
  );
}
