from app.data.repositories.memory_store import memory_store
from app.use_cases.universal_search_use_case import UniversalSearchUseCase
from app.use_cases.get_person_recommendations_use_case import GetPersonRecommendationsUseCase
from app.use_cases.get_stock_related_figures_use_case import GetStockRelatedFiguresUseCase
from app.use_cases.get_theme_cluster_use_case import GetThemeClusterUseCase
from app.use_cases.get_deep_dive_path_use_case import GetDeepDivePathUseCase

# Use Case Singletons wired via Dependency Injection
universal_search_use_case = UniversalSearchUseCase(
    person_repo=memory_store,
    company_repo=memory_store,
    theme_repo=memory_store
)

person_recommendations_use_case = GetPersonRecommendationsUseCase(
    person_repo=memory_store,
    company_repo=memory_store,
    network_repo=memory_store
)

stock_related_figures_use_case = GetStockRelatedFiguresUseCase(
    person_repo=memory_store,
    company_repo=memory_store,
    theme_repo=memory_store,
    network_repo=memory_store
)

theme_cluster_use_case = GetThemeClusterUseCase(
    theme_repo=memory_store,
    person_repo=memory_store,
    company_repo=memory_store,
    network_repo=memory_store
)

deep_dive_path_use_case = GetDeepDivePathUseCase(
    person_repo=memory_store,
    company_repo=memory_store,
    network_repo=memory_store
)
