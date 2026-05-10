import { Clock3 } from "lucide-react";
import type { RunningTask } from "@/services/types";
import { formatDuration, formatMemory, formatProjectType } from "@/utils/format";

export function RunningTaskRail({ tasks }: { tasks: RunningTask[] }) {
  return (
    <section className="task-rail" aria-labelledby="running-tasks-title">
      <div className="section-kicker">
        <Clock3 size={16} aria-hidden="true" />
        <span>Runtime rail</span>
      </div>
      <h2 id="running-tasks-title">Task đang chạy</h2>

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
              <div className="progress-track" aria-label={`Tiến độ ${task.progressPercent}%`}>
                <span style={{ width: `${task.progressPercent}%` }} />
              </div>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
