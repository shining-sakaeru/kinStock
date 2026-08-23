from typing import List, Optional, Dict
from collections import defaultdict
from app.domain.repositories.person_repository import PersonRepository
from app.domain.repositories.company_repository import CompanyRepository
from app.domain.repositories.theme_repository import ThemeRepository
from app.domain.repositories.network_graph_repository import NetworkGraphRepository
from app.domain.entities.weight_settings import WeightSettings
from app.data.mappers.domain_dto_mapper import DomainDtoMapper
from app.data.dtos.theme_dtos import ThemeClusterResponseDto, ThemeDto
from app.data.dtos.person_dtos import PersonDto
from app.data.dtos.stock_dtos import RankedStockItemDto
from app.use_cases.get_person_recommendations_use_case import GetPersonRecommendationsUseCase

class GetThemeClusterUseCase:
    def __init__(
        self,
        theme_repo: ThemeRepository,
        person_repo: PersonRepository,
        company_repo: CompanyRepository,
        network_repo: NetworkGraphRepository
    ):
        self.theme_repo = theme_repo
        self.person_repo = person_repo
        self.company_repo = company_repo
        self.network_repo = network_repo
        self.person_recs_use_case = GetPersonRecommendationsUseCase(person_repo, company_repo, network_repo)

    def execute(
        self,
        theme_id: str,
        weights: Optional[WeightSettings] = None
    ) -> Optional[ThemeClusterResponseDto]:
        theme = self.theme_repo.get_theme_by_id(theme_id)
        if not theme:
            return None

        w_settings = weights or WeightSettings.default()
        theme_figures = self.person_repo.get_persons_by_theme(theme_id)
        figures_dtos = [DomainDtoMapper.to_person_dto(p) for p in theme_figures]

        # Aggregate top theme beneficiary stocks across all figures in this theme
        stock_scores: Dict[str, RankedStockItemDto] = {}

        for fig in theme_figures:
            res = self.person_recs_use_case.execute(fig.id, weights=w_settings)
            if not res:
                continue
            for item in res.recommendations:
                if item.company_id not in stock_scores or item.relevance_score > stock_scores[item.company_id].relevance_score:
                    stock_scores[item.company_id] = item

        top_stocks = list(stock_scores.values())
        top_stocks.sort(key=lambda x: (x.relevance_score, x.price_change_rate), reverse=True)
        for idx, s in enumerate(top_stocks):
            s.rank = idx + 1

        return ThemeClusterResponseDto(
            status="success",
            theme=DomainDtoMapper.to_theme_dto(theme),
            key_figures=figures_dtos,
            top_theme_stocks=top_stocks
        )
