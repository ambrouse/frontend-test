from __future__ import annotations

from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime
from threading import Lock
from time import monotonic
from uuid import uuid4

from app.schemas.models import RunningTask, TaskStatus

TERMINAL_TASK_STATUSES: set[TaskStatus] = {"completed", "failed"}


class TaskStore:
    def __init__(self) -> None:
        self._lock = Lock()
        self._executor = ThreadPoolExecutor(max_workers=4, thread_name_prefix="provider-task")
        self._tasks: dict[str, RunningTask] = {}
        self._started_at_monotonic: dict[str, float] = {}
        self._finished_at_monotonic: dict[str, float] = {}

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
            self._prune_locked()
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
            self._prune_locked()
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
            if updated.status in TERMINAL_TASK_STATUSES:
                self._finished_at_monotonic[task_id] = monotonic()
            else:
                self._finished_at_monotonic.pop(task_id, None)
            return updated

    def get(self, task_id: str) -> RunningTask | None:
        with self._lock:
            self._prune_locked()
            task = self._tasks.get(task_id)
        if task is None:
            return None
        return self.update(task.id) or task

    def list_tasks(self, *, include_finished: bool = True) -> list[RunningTask]:
        with self._lock:
            self._prune_locked()
            task_ids = list(self._tasks)
        tasks = [task for task_id in task_ids if (task := self.get(task_id)) is not None]
        if not include_finished:
            tasks = [task for task in tasks if task.status not in TERMINAL_TASK_STATUSES]
        tasks.sort(key=lambda task: self._started_at_monotonic.get(task.id, 0.0), reverse=True)
        return tasks

    def active(self) -> list[RunningTask]:
        return self.list_tasks(include_finished=False)

    def find_active_by_project(self, project_id: str) -> RunningTask | None:
        with self._lock:
            self._prune_locked()
            active = [
                task
                for task in self._tasks.values()
                if task.projectId == project_id and task.status not in TERMINAL_TASK_STATUSES
            ]
            if not active:
                return None
            active.sort(key=lambda task: self._started_at_monotonic.get(task.id, 0.0), reverse=True)
            return active[0]

    def clear(self, *, scope: str = "finished") -> int:
        with self._lock:
            if scope == "all":
                removed = len(self._tasks)
                self._tasks.clear()
                self._started_at_monotonic.clear()
                self._finished_at_monotonic.clear()
                return removed

            finished_task_ids = [
                task_id for task_id, task in self._tasks.items() if task.status in TERMINAL_TASK_STATUSES
            ]
            for task_id in finished_task_ids:
                self._tasks.pop(task_id, None)
                self._started_at_monotonic.pop(task_id, None)
                self._finished_at_monotonic.pop(task_id, None)
            return len(finished_task_ids)

    def _prune_locked(self, *, completed_ttl_sec: int = 900, max_history: int = 250) -> None:
        now = monotonic()

        expired_task_ids = [
            task_id
            for task_id, finished_at in self._finished_at_monotonic.items()
            if (now - finished_at) >= completed_ttl_sec
        ]
        for task_id in expired_task_ids:
            self._tasks.pop(task_id, None)
            self._started_at_monotonic.pop(task_id, None)
            self._finished_at_monotonic.pop(task_id, None)

        if len(self._tasks) <= max_history:
            return

        terminal_tasks = [task for task in self._tasks.values() if task.status in TERMINAL_TASK_STATUSES]
        terminal_tasks.sort(key=lambda task: self._finished_at_monotonic.get(task.id, 0.0))
        while len(self._tasks) > max_history and terminal_tasks:
            stale = terminal_tasks.pop(0)
            self._tasks.pop(stale.id, None)
            self._started_at_monotonic.pop(stale.id, None)
            self._finished_at_monotonic.pop(stale.id, None)

    def _run_task(self, task_id: str, fn: Callable[[str], None]) -> None:
        try:
            fn(task_id)
        except Exception as exc:  # pragma: no cover - defensive boundary
            self.update(task_id, status="failed", current_step=str(exc), progress_percent=100)


task_store = TaskStore()
