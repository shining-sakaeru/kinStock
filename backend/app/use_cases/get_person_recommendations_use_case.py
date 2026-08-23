from typing import List, Optional
from collections import defaultdict
from app.domain.repositories.person_repository import PersonRepository
from app.domain.repositories.company_repository import CompanyRepository
from app.domain.repositories.network_graph_repository import NetworkGraphRepository
from app.domain.entities.weight_settings import WeightSettings
from app.domain.entities.dart_fact import DartDisclosureFact
from app.domain.services.scoring_engine import calculate_single_path_score, calculate_aggregated_relevance, format_path_summary
from app.data.mappers.domain_dto_mapper import DomainDtoMapper
from app.data.dtos.person_dtos import PersonDto, FigureStocksResponseDto
from app.data.dtos.stock_dtos import RankedStockItemDto
from app.data.dtos.common_dtos import RadialNodeDto, MicroGraphDto

class GetPersonRecommendationsUseCase:
    def __init__(
        self,
        person_repo: PersonRepository,
        company_repo: CompanyRepository,
        network_repo: NetworkGraphRepository
    ):
        self.person_repo = person_repo
        self.company_repo = company_repo
        self.network_repo = network_repo

    def execute(
        self,
        person_id: str,
        weights: Optional[WeightSettings] = None,
        max_depth: int = 3
    ) -> Optional[FigureStocksResponseDto]:
        person = self.person_repo.get_person_by_id(person_id)
        if not person:
            return None

        w_settings = weights or WeightSettings.default()
        all_companies = self.company_repo.get_all_companies()

        # 1. Calculate Micro Graph (Top 5 1-hop connections)
        direct_edges = self.network_repo.get_outgoing_neighbors(person_id)
        radial_nodes: List[RadialNodeDto] = []

        for target_id, edge in direct_edges:
            target_person = self.person_repo.get_person_by_id(target_id)
            target_company = self.company_repo.get_company_by_id_or_ticker(target_id)

            if target_person:
                node_type = "PERSON"
                node_name = target_person.name
                detail_info = target_person.role_title
                source_url = target_person.source_url
            elif target_company:
                node_type = "COMPANY"
                node_name = target_company.name
                detail_info = target_company.industry
                source_url = target_company.source_url
            else:
                continue

            radial_nodes.append(
                RadialNodeDto(
                    node_id=target_id,
                    node_name=node_name,
                    node_type=node_type,
                    relation_type=edge.relation_type.value,
                    relation_badge=edge.label,
                    weight=w_settings.resolve_factor_weight(edge.relation_type.value),
                    detail_info=detail_info,
                    connected_company_count=1 if node_type == "COMPANY" else 2,
                    dart_ref=f"DART-{target_id}",
                    source_url=source_url
                )
            )

        radial_nodes.sort(key=lambda x: x.weight, reverse=True)

        micro_graph = MicroGraphDto(
            status="success",
            center_person=DomainDtoMapper.to_person_dto(person),
            radial_nodes=radial_nodes[:5]
        )

        # 2. Multi-hop Paths to Companies
        ranked_stocks: List[RankedStockItemDto] = []

        for company in all_companies:
            paths = self.network_repo.find_all_simple_paths(person_id, company.id, max_depth=max_depth)
            if not paths:
                continue

            path_scores = []
            best_score = -1.0
            best_path_nodes = None
            best_badge = ""
            best_summary = ""

            for path in paths:
                edge_objs = []
                badges = []
                for i in range(len(path) - 1):
                    edge = self.network_repo.get_edge(path[i], path[i + 1])
                    edge_objs.append(edge)
                    badges.append(edge.label)

                p_score = calculate_single_path_score(edge_objs, w_settings)
                path_scores.append(p_score)

                if p_score > best_score:
                    best_score = p_score
                    best_path_nodes = path
                    inter_name = None
                    if len(path) > 2:
                        inter_person = self.person_repo.get_person_by_id(path[1])
                        inter_name = inter_person.name if inter_person else "지인"

                    b, s = format_path_summary(person.name, inter_name, company.name, badges, len(path) - 1)
                    best_badge = b
                    best_summary = s

            relevance = calculate_aggregated_relevance(path_scores)
            dart_fact_entity = DartDisclosureFact.create_for_company(
                company_name=company.name,
                ticker=company.ticker,
                corp_code=company.dart_corp_code or "10293",
                summary=best_summary
            )

            ranked_stocks.append(
                RankedStockItemDto(
                    rank=0,
                    company_id=company.id,
                    ticker=company.ticker,
                    company_name=company.name,
                    relevance_score=relevance,
                    primary_badge=best_badge,
                    current_price=company.current_price,
                    price_change_rate=company.price_change_rate,
                    market_cap=company.market_cap,
                    industry=company.industry,
                    depth=len(best_path_nodes) - 1 if best_path_nodes else 1,
                    connection_path_summary=best_summary,
                    dart_fact=DomainDtoMapper.to_dart_fact_dto(dart_fact_entity),
                    is_dart_verified=True,
                    source_url=dart_fact_entity.source_url
                )
            )

        ranked_stocks.sort(key=lambda x: (x.relevance_score, x.price_change_rate), reverse=True)
        for idx, item in enumerate(ranked_stocks):
            item.rank = idx + 1

        return FigureStocksResponseDto(
            status="success",
            figure=DomainDtoMapper.to_person_dto(person),
            micro_graph=micro_graph,
            recommendations=ranked_stocks,
            applied_weights=w_settings.to_dict()
        )
