from fastapi import APIRouter, HTTPException, Query

from app.schemas.models import HubProject, ProviderListResponse
from app.services.provider_registry import provider_registry

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
