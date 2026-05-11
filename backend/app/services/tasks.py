from app.schemas.models import RunningTask
from app.services.task_store import task_store


def active_tasks() -> list[RunningTask]:
    return task_store.active()


def all_tasks(*, include_completed: bool = False) -> list[RunningTask]:
    return task_store.list_tasks(include_finished=include_completed)


def get_task(task_id: str) -> RunningTask | None:
    return task_store.get(task_id)


def clear_tasks(*, scope: str = "finished") -> int:
    return task_store.clear(scope=scope)


def task_summary() -> dict:
    tasks = active_tasks()
    return {"count": len(tasks), "tasks": tasks}
