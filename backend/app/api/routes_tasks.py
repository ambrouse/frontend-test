from fastapi import APIRouter, HTTPException

from app.services.tasks import all_tasks, get_task, task_summary

router = APIRouter(prefix="/api/tasks", tags=["tasks"])


@router.get("")
def tasks() -> dict:
    tasks_list = all_tasks()
    return {"tasks": tasks_list, "total": len(tasks_list)}


@router.get("/active")
def active() -> dict:
    return task_summary()


@router.get("/{task_id}")
def task_detail(task_id: str) -> dict:
    task = get_task(task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return task.model_dump()
