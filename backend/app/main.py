from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes_hardware import router as hardware_router
from app.api.routes_health import router as health_router
from app.api.routes_providers import router as providers_router
from app.api.routes_tasks import router as tasks_router

app = FastAPI(title="AI Hub Backend", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1):30\d{2}",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(hardware_router)
app.include_router(providers_router)
app.include_router(tasks_router)
