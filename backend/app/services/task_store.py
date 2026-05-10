from __future__ import annotations

from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime
from threading import Lock
from time import monotonic
from uuid import uuid4

from app.schemas.models import RunningTask, TaskStatus


class TaskStore:
    def __init__(self) -> None:
        self._lock = Lock()
        self._executor = ThreadPoolExecutor(max_workers=4, thread_name_prefix="provider-task")
        self._tasks: dict[str, RunningTask] = {}
        self._started_at_monotonic: dict[str, float] = {}

    def create(
        self,
        *,
        project_id: str,
        project_name: str,
        project_type: str,
        status: TaskStatus,
        current_step: str,
        progress_percent: int = 1,
    ) -> RunningTask:
        task = RunningTask(
            id=f"task-{uuid4().hex[:12]}",
            projectId=project_id,
            projectName=project_name,
            type=project_type,  # type: ignore[arg-type]
            status=status,
            startedAt=datetime.now(UTC).isoformat(),
            durationSec=0,
            cpuPercent=0,
            gpuPercent=0,
            ramMb=0,
            vramMb=0,
            currentStep=current_step,
            progressPercent=progress_percent,
        )
        with self._lock:
            self._tasks[task.id] = task
            self._started_at_monotonic[task.id] = monotonic()
        return task

    def submit(self, task: RunningTask, fn: Callable[[str], None]) -> None:
        self._executor.submit(self._run_task, task.id, fn)

    def update(
        self,
        task_id: str,
        *,
        status: TaskStatus | None = None,
        current_step: str | None = None,
        progress_percent: int | None = None,
    ) -> RunningTask | None:
        with self._lock:
            task = self._tasks.get(task_id)
            if task is None:
                return None
            data = task.model_dump()
            if status is not None:
                data["status"] = status
            if current_step is not None:
                data["currentStep"] = current_step
            if progress_percent is not None:
                data["progressPercent"] = progress_percent
            data["durationSec"] = int(monotonic() - self._started_at_monotonic.get(task_id, monotonic()))
            updated = RunningTask.model_validate(data)
            self._tasks[task_id] = updated
            return updated

    def get(self, task_id: str) -> RunningTask | None:
        with self._lock:
            task = self._tasks.get(task_id)
        if task is None:
            return None
        return self.update(task.id) or task

    def list_tasks(self) -> list[RunningTask]:
        with self._lock:
            task_ids = list(self._tasks)
        return [task for task_id in task_ids if (task := self.get(task_id)) is not None]

    def active(self) -> list[RunningTask]:
        return [task for task in self.list_tasks() if task.status not in {"completed", "failed"}]

    def _run_task(self, task_id: str, fn: Callable[[str], None]) -> None:
        try:
            fn(task_id)
        except Exception as exc:  # pragma: no cover - defensive boundary
            self.update(task_id, status="failed", current_step=str(exc), progress_percent=100)


task_store = TaskStore()
