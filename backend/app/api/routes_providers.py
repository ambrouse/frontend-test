from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse

from app.schemas.models import (
    HubProject,
    ProviderActionRequest,
    ProviderActionResponse,
    ProviderConfig,
    ProviderListResponse,
    ProviderLogsResponse,
    ProviderMetrics,
    ProviderStatus,
)
from app.services.provider_registry import IMAGE_EXTENSIONS, provider_registry
from app.services.provider_runtime import (
    delete_provider,
    install_provider,
    patch_provider_config,
    provider_config,
    provider_logs,
    provider_metrics,
    provider_status,
    run_provider,
    stop_provider,
)

router = APIRouter(prefix="/api/providers", tags=["providers"])


@router.get("", response_model=ProviderListResponse)
def list_providers(type: str | None = Query(default=None), q: str | None = Query(default=None)) -> ProviderListResponse:
    return provider_registry.list_providers(project_type=type, query=q)


@router.get("/featured", response_model=ProviderListResponse)
def featured_providers(limit: int = Query(default=30, ge=1, le=60)) -> ProviderListResponse:
    return provider_registry.featured(limit=limit)


@router.get("/summary")
def provider_summary() -> dict:
    providers = provider_registry.list_providers().providers
    return {
        "total": len(providers),
        "ready": sum(1 for provider in providers if provider.compatibility and provider.compatibility.level != "red"),
        "blocked": sum(1 for provider in providers if provider.compatibility and provider.compatibility.level == "red"),
        "installed": sum(1 for provider in providers if provider.installStatus == "installed"),
        "running": sum(1 for provider in providers if provider.runStatus == "running"),
    }


@router.get("/{provider_id}", response_model=HubProject)
def provider_detail(provider_id: str) -> HubProject:
    provider = provider_registry.get_provider(provider_id)
    if provider is None:
        raise HTTPException(status_code=404, detail="Provider not found")
    return provider


@router.get("/{provider_id}/assets/{asset_path:path}", response_class=FileResponse)
def provider_asset(provider_id: str, asset_path: str) -> FileResponse:
    provider = provider_registry.get_provider(provider_id)
    if provider is None:
        raise HTTPException(status_code=404, detail="Provider not found")

    provider_root = provider_registry.provider_root(provider_id).resolve()
    asset = (provider_root / asset_path).resolve()
    allowed_roots = [(provider_root / name).resolve() for name in ("media", "images", "assets")]
    if not any(asset == root or root in asset.parents for root in allowed_roots):
        raise HTTPException(status_code=404, detail="Provider asset not found")
    if not asset.is_file() or asset.suffix.lower() not in IMAGE_EXTENSIONS:
        raise HTTPException(status_code=404, detail="Provider asset not found")
    return FileResponse(asset)


@router.get("/{provider_id}/status", response_model=ProviderStatus)
def status(provider_id: str) -> ProviderStatus:
    return _provider_call(lambda: provider_status(provider_id))


@router.get("/{provider_id}/metrics", response_model=ProviderMetrics)
def metrics(provider_id: str) -> ProviderMetrics:
    return _provider_call(lambda: provider_metrics(provider_id))


@router.get("/{provider_id}/logs", response_model=ProviderLogsResponse)
def logs(
    provider_id: str,
    tail: int = Query(default=200, ge=1, le=1000),
    cursor: int | None = Query(default=None, ge=0),
    level: str | None = Query(default=None),
) -> ProviderLogsResponse:
    return _provider_call(lambda: provider_logs(provider_id, tail=tail, cursor=cursor, level=level))


@router.get("/{provider_id}/config", response_model=ProviderConfig)
def config(provider_id: str) -> ProviderConfig:
    return _provider_call(lambda: provider_config(provider_id))


@router.patch("/{provider_id}/config", response_model=ProviderConfig)
def update_config(provider_id: str, patch: dict) -> ProviderConfig:
    return _provider_call(lambda: patch_provider_config(provider_id, patch))


@router.post("/{provider_id}/install", response_model=ProviderActionResponse)
def install(provider_id: str, request: ProviderActionRequest | None = None) -> ProviderActionResponse:
    return _provider_call(lambda: install_provider(provider_id, request or ProviderActionRequest()))


@router.post("/{provider_id}/run", response_model=ProviderActionResponse)
def run(provider_id: str, request: ProviderActionRequest | None = None) -> ProviderActionResponse:
    return _provider_call(lambda: run_provider(provider_id, request or ProviderActionRequest()))


@router.post("/{provider_id}/stop", response_model=ProviderActionResponse)
def stop(provider_id: str, request: ProviderActionRequest | None = None) -> ProviderActionResponse:
    return _provider_call(lambda: stop_provider(provider_id, request or ProviderActionRequest()))


@router.delete("/{provider_id}", response_model=ProviderActionResponse)
def delete(provider_id: str, request: ProviderActionRequest | None = None) -> ProviderActionResponse:
    return _provider_call(lambda: delete_provider(provider_id, request or ProviderActionRequest()))


def _provider_call(callback):
    try:
        return callback()
    except KeyError:
        raise HTTPException(status_code=404, detail="Provider not found") from None
