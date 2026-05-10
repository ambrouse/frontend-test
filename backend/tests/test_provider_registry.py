from app.services.provider_registry import provider_registry


def test_featured_providers_are_deterministic() -> None:
    first = [provider.id for provider in provider_registry.featured(limit=10).providers]
    second = [provider.id for provider in provider_registry.featured(limit=10).providers]
    assert first == second


def test_query_filter() -> None:
    response = provider_registry.list_providers(query="qwen")
    assert response.total >= 1
    assert any("qwen" in provider.name.lower() for provider in response.providers)
