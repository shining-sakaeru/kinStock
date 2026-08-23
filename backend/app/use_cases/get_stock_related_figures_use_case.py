from typing import List, Optional
from app.domain.repositories.person_repository import PersonRepository
from app.domain.repositories.company_repository import CompanyRepository
from app.domain.repositories.theme_repository import ThemeRepository
from app.domain.repositories.network_graph_repository import NetworkGraphRepository
from app.domain.entities.weight_settings import WeightSettings
from app.domain.entities.dart_fact import DartDisclosureFact
from app.domain.services.scoring_engine import calculate_single_path_score, calculate_aggregated_relevance, format_path_summary
from app.data.mappers.domain_dto_mapper import DomainDtoMapper
from app.data.dtos.stock_dtos import CompanyDto, RankedFigureItemDto, StockFiguresResponseDto
from app.data.dtos.common_dtos import RadialNodeDto, MicroGraphDto

class GetStockRelatedFiguresUseCase:
    def __init__(
        self,
        person_repo: PersonRepository,
        company_repo: CompanyRepository,
        theme_repo: ThemeRepository,
        network_repo: NetworkGraphRepository
    ):
        self.person_repo = person_repo
        self.company_repo = company_repo
        self.theme_repo = theme_repo
        self.network_repo = network_repo

    def execute(
        self,
        stock_code_or_id: str,
        weights: Optional[WeightSettings] = None,
        max_depth: int = 3
    ) -> Optional[StockFiguresResponseDto]:
        company = self.company_repo.get_company_by_id_or_ticker(stock_code_or_id)
        if not company:
            return None

        w_settings = weights or WeightSettings.default()
        all_persons = self.person_repo.get_all_persons()

        # 1. Company Micro Radar (Direct connected executives/persons)
        incoming_edges = self.network_repo.get_incoming_neighbors(company.id)
        radial_nodes: List[RadialNodeDto] = []

        for p_id, edge in incoming_edges:
            p_obj = self.person_repo.get_person_by_id(p_id)
            if p_obj:
                radial_nodes.append(
                    RadialNodeDto(
                        node_id=p_id,
                        node_name=p_obj.name,
                        node_type="PERSON",
                        relation_type=edge.relation_type.value,
                        relation_badge=edge.label,
                        weight=w_settings.resolve_factor_weight(edge.relation_type.value),
                        detail_info=p_obj.role_title,
                        connected_company_count=1,
                        dart_ref=f"DART-FACT-{p_id}",
                        source_url=p_obj.source_url
                    )
                )

        radial_nodes.sort(key=lambda x: x.weight, reverse=True)
        micro_graph = MicroGraphDto(
            status="success",
            center_company=DomainDtoMapper.to_company_dto(company),
            radial_nodes=radial_nodes[:5]
        )

        # 2. Reverse Lookup: From all Persons to this Company
        ranked_figures: List[RankedFigureItemDto] = []

        for person in all_persons:
            paths = self.network_repo.find_all_simple_paths(person.id, company.id, max_depth=max_depth)
            if not paths:
                continue

            path_scores = []
            best_score = -1.0
            best_path = None
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
                    best_path = path
                    inter_name = None
                    if len(path) > 2:
                        inter_p = self.person_repo.get_person_by_id(path[1])
                        inter_name = inter_p.name if inter_p else "지인"

                    b, s = format_path_summary(person.name, inter_name, company.name, badges, len(path) - 1)
                    best_badge = b
                    best_summary = s

            relevance = calculate_aggregated_relevance(path_scores)
            theme_obj = self.theme_repo.get_theme_by_id(person.theme_id)
            theme_title = theme_obj.title if theme_obj else "정치/경제 테마"

            dart_fact_entity = DartDisclosureFact.create_for_company(
                company_name=company.name,
                ticker=company.ticker,
                corp_code=company.dart_corp_code or "10293",
                summary=best_summary
            )

            ranked_figures.append(
                RankedFigureItemDto(
                    rank=0,
                    figure_id=person.id,
                    name=person.name,
                    role_title=person.role_title,
                    theme_id=person.theme_id,
                    theme_title=theme_title,
                    relevance_score=relevance,
                    primary_badge=best_badge,
                    depth=len(best_path) - 1 if best_path else 1,
                    connection_path_summary=best_summary,
                    dart_fact=DomainDtoMapper.to_dart_fact_dto(dart_fact_entity),
                    source_url=person.source_url
                )
            )

        ranked_figures.sort(key=lambda x: x.relevance_score, reverse=True)
        for idx, fig in enumerate(ranked_figures):
            fig.rank = idx + 1

        return StockFiguresResponseDto(
            status="success",
            company=DomainDtoMapper.to_company_dto(company),
            micro_graph=micro_graph,
            related_figures=ranked_figures,
            applied_weights=w_settings.to_dict()
        )
