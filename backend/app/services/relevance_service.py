from typing import List, Optional, Dict
from app.core.graph_engine import GraphEngine
from app.core.models import (
    Theme, Person, Company, MicroGraphResponse, RecommendationsResponse,
    StockRelatedFiguresResponse, DeepDivePathResponse, FigureRelatedStocksResponse,
    AI_DEFAULT_WEIGHTS, WeightFactorMeta, WeightBaselineResponse
)
from app.data.seed_data import populate_seed_data

class RelevanceService:
    def __init__(self):
        self.engine = GraphEngine()
        populate_seed_data(self.engine)

    def get_themes(self) -> List[Theme]:
        return self.engine.get_all_themes()

    def get_theme(self, theme_id: str) -> Optional[Theme]:
        return self.engine.get_theme(theme_id)

    def get_figures_by_theme(self, theme_id: str) -> List[Person]:
        return self.engine.get_figures_by_theme(theme_id)

    def get_all_persons(self) -> List[Person]:
        return self.engine.get_all_persons()

    def get_person(self, person_id: str) -> Optional[Person]:
        return self.engine.get_person(person_id)

    def get_all_companies(self) -> List[Company]:
        return self.engine.get_all_companies()

    def get_company(self, company_id: str) -> Optional[Company]:
        return self.engine.get_company(company_id)

    def get_micro_graph(
        self,
        person_id: str,
        top_k: int = 5,
        weight_overrides: Optional[Dict[str, float]] = None
    ) -> Optional[MicroGraphResponse]:
        return self.engine.get_micro_graph(person_id=person_id, top_k=top_k, weight_overrides=weight_overrides)

    def get_recommendations(
        self,
        person_id: str,
        max_depth: int = 3,
        weight_overrides: Optional[Dict[str, float]] = None
    ) -> Optional[RecommendationsResponse]:
        return self.engine.calculate_recommendations(
            person_id=person_id,
            max_depth=max_depth,
            weight_overrides=weight_overrides
        )

    def get_figure_related_stocks(
        self,
        figure_id: str,
        weight_overrides: Optional[Dict[str, float]] = None
    ) -> Optional[FigureRelatedStocksResponse]:
        return self.engine.get_figure_related_stocks(figure_id, weight_overrides=weight_overrides)

    def get_stock_related_figures(
        self,
        stock_code_or_id: str,
        weight_overrides: Optional[Dict[str, float]] = None
    ) -> Optional[StockRelatedFiguresResponse]:
        return self.engine.calculate_stock_related_figures(
            company_id_or_ticker=stock_code_or_id,
            weight_overrides=weight_overrides
        )

    def get_deep_dive_path(
        self,
        person_id: str,
        company_id: str,
        weight_overrides: Optional[Dict[str, float]] = None
    ) -> Optional[DeepDivePathResponse]:
        return self.engine.get_deep_dive_path(person_id=person_id, company_id=company_id, weight_overrides=weight_overrides)

    def get_weight_baseline(self) -> WeightBaselineResponse:
        return WeightBaselineResponse(
            status="success",
            factors={
                "executive_family": WeightFactorMeta(
                    key="executive_family",
                    title="직무 실권 및 최대주주",
                    default_value=0.95,
                    description="DART 공시상 대표이사·사내이사 및 대주주 지배력 (대표이사 가중치 1.3배 보정)"
                ),
                "exclusive_cohort": WeightFactorMeta(
                    key="exclusive_cohort",
                    title="폐쇄형 엘리트 네트워크",
                    default_value=0.85,
                    description="사법연수원·행정고시 등 폐쇄적 고위 기수 네트워크의 장기적 정책·이권 결속력"
                ),
                "direct_alumni": WeightFactorMeta(
                    key="direct_alumni",
                    title="직접 학연 (동문)",
                    default_value=0.70,
                    description="동일 고등학교 및 대학교 동일 학과 출신 네트워크"
                ),
                "regional_ties": WeightFactorMeta(
                    key="regional_ties",
                    title="지연 / 동향",
                    default_value=0.45,
                    description="동일 출신 지역 및 향우회 네트워크"
                ),
                "decay_factor": WeightFactorMeta(
                    key="decay_factor",
                    title="다단계 감가 계수",
                    default_value=0.60,
                    description="2-Depth 이상 다단계 연결 시 적용되는 단계별 감가율 (기본 0.60x)"
                ),
            }
        )

    def export_cypher(self) -> str:
        return self.engine.export_neo4j_cypher()

relevance_service = RelevanceService()
