from app.schemas.models import RunningTask
from app.services.provider_seed import RUNNING_TASKS


def active_tasks() -> list[RunningTask]:
    return [RunningTask.model_validate(task) for task in RUNNING_TASKS if task["status"] in {"running", "installing"}]


def task_summary() -> dict:
    tasks = active_tasks()
    return {"count": len(tasks), "tasks": tasks}
