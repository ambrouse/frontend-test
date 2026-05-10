from fastapi import APIRouter

from app.services.tasks import active_tasks, task_summary

router = APIRouter(prefix="/api/tasks", tags=["tasks"])


@router.get("")
def tasks() -> dict:
    tasks_list = active_tasks()
    return {"tasks": tasks_list, "total": len(tasks_list)}


@router.get("/active")
def active() -> dict:
    return task_summary()
