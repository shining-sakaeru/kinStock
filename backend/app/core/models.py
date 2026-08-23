from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class NodeType(str, Enum):
    PERSON = "PERSON"
    COMPANY = "COMPANY"
    ORGANIZATION = "ORGANIZATION"
    THEME = "THEME"

class PersonCategory(str, Enum):
    POLITICIAN = "POLITICIAN"
    BUSINESSMAN = "BUSINESSMAN"
    PUBLIC_OFFICIAL = "PUBLIC_OFFICIAL"
    INFLUENCER = "INFLUENCER"

class ThemeCode(str, Enum):
    PRESIDENTIAL_ELECTION = "PRESIDENTIAL_ELECTION"
    GENERAL_ELECTION = "GENERAL_ELECTION"
    CABINET_POLICY = "CABINET_POLICY"
    CONGLOMERATE_GOVERNANCE = "CONGLOMERATE_GOVERNANCE"
    DIPLOMATIC_MISSION = "DIPLOMATIC_MISSION"

class RelationType(str, Enum):
    # Person <-> Person
    BLOOD_RELATION = "BLOOD_RELATION"
    SPOUSE_FAMILY = "SPOUSE_FAMILY"
    POLITICAL_CAMP = "POLITICAL_CAMP"
    WORK_COLLEAGUE = "WORK_COLLEAGUE"
    EXCLUSIVE_COHORT = "EXCLUSIVE_COHORT"
    HIGH_SCHOOL_ALUMNI = "HIGH_SCHOOL_ALUMNI"
    UNIV_ALUMNI = "UNIV_ALUMNI"
    HOMETOWN_CONNECTION = "HOMETOWN_CONNECTION"
    
    # Person <-> Company (DART 전자공시 팩트 기반)
    MAJOR_SHAREHOLDER = "MAJOR_SHAREHOLDER"
    FOUNDER = "FOUNDER"
    CEO_OR_EXECUTIVE = "CEO_OR_EXECUTIVE"
    OUTSIDE_DIRECTOR = "OUTSIDE_DIRECTOR"
    POLICY_THEME = "POLICY_THEME"
    DIPLOMATIC_DELEGATION = "DIPLOMATIC_DELEGATION"

# AI Optimal Baseline Weights
AI_DEFAULT_WEIGHTS = {
    "executive_family": 0.95,
    "exclusive_cohort": 0.85,
    "direct_alumni": 0.70,
    "regional_ties": 0.45,
    "decay_factor": 0.60,
}

RELATION_METADATA: Dict[RelationType, Dict[str, Any]] = {
    RelationType.BLOOD_RELATION: {"weight_key": "executive_family", "default_weight": 0.95, "badge": "혈연관계", "category": "혈연"},
    RelationType.SPOUSE_FAMILY: {"weight_key": "executive_family", "default_weight": 0.85, "badge": "인척관계", "category": "혈연"},
    RelationType.MAJOR_SHAREHOLDER: {"weight_key": "executive_family", "default_weight": 0.95, "badge": "최대주주", "category": "지분"},
    RelationType.FOUNDER: {"weight_key": "executive_family", "default_weight": 0.90, "badge": "창업주", "category": "임원/지분"},
    RelationType.CEO_OR_EXECUTIVE: {"weight_key": "executive_family", "default_weight": 0.95, "badge": "대표/임원", "category": "임원"},
    RelationType.OUTSIDE_DIRECTOR: {"weight_key": "executive_family", "default_weight": 0.70, "badge": "사외이사", "category": "임원"},
    RelationType.EXCLUSIVE_COHORT: {"weight_key": "exclusive_cohort", "default_weight": 0.85, "badge": "엘리트동기", "category": "경력/고시"},
    RelationType.WORK_COLLEAGUE: {"weight_key": "exclusive_cohort", "default_weight": 0.75, "badge": "직장동료", "category": "경력"},
    RelationType.POLITICAL_CAMP: {"weight_key": "exclusive_cohort", "default_weight": 0.80, "badge": "정치캠프", "category": "정치/조직"},
    RelationType.HIGH_SCHOOL_ALUMNI: {"weight_key": "direct_alumni", "default_weight": 0.70, "badge": "고교동문", "category": "학연"},
    RelationType.UNIV_ALUMNI: {"weight_key": "direct_alumni", "default_weight": 0.70, "badge": "대학동문", "category": "학연"},
    RelationType.HOMETOWN_CONNECTION: {"weight_key": "regional_ties", "default_weight": 0.45, "badge": "지연연관", "category": "지연"},
    RelationType.POLICY_THEME: {"weight_key": "regional_ties", "default_weight": 0.50, "badge": "정책수혜", "category": "정책/테마"},
    RelationType.DIPLOMATIC_DELEGATION: {"weight_key": "exclusive_cohort", "default_weight": 0.75, "badge": "사절단동행", "category": "외교/통상"},
}

class DartFact(BaseModel):
    report_title: str
    report_code: str
    rcp_no: str
    filing_date: str
    verified_fact: str
    source_url: str

class Theme(BaseModel):
    id: str
    code: ThemeCode
    title: str
    short_title: str
    description: str
    icon_name: str
    badge_color: str
    figure_count: int = 0

class Person(BaseModel):
    id: str
    name: str
    category: PersonCategory
    role_title: str
    theme_id: str = "theme_presidential"
    profile_img_url: Optional[str] = None
    hometown: Optional[str] = None
    alma_mater: List[str] = Field(default_factory=list)
    cohort_info: Optional[str] = None
    key_summary: Optional[str] = None
    source_url: str = "https://www.assembly.go.kr"

class Company(BaseModel):
    id: str
    ticker: str
    name: str
    industry: str
    current_price: float
    price_change_rate: float
    market_cap: str
    description: Optional[str] = None
    dart_corp_code: Optional[str] = None
    source_url: Optional[str] = None

# Micro Graph schemas
class RadialNode(BaseModel):
    node_id: str
    node_name: str
    node_type: NodeType
    relation_type: RelationType
    relation_badge: str
    weight: float
    detail_info: Optional[str] = None
    connected_company_count: int = 0
    dart_ref: Optional[str] = None
    source_url: Optional[str] = None

class MicroGraphResponse(BaseModel):
    status: str = "success"
    center_person: Optional[Person] = None
    center_company: Optional[Company] = None
    radial_nodes: List[RadialNode]

# Person-Centric Ranked Recommendations (인물 중심 -> 연관 주식 리스트)
class RankedStockItem(BaseModel):
    rank: int
    company_id: str
    ticker: str
    company_name: str
    relevance_score: float
    primary_badge: str
    current_price: float
    price_change_rate: float
    market_cap: str
    industry: str
    depth: int
    connection_path_summary: str
    dart_fact: Optional[DartFact] = None
    is_dart_verified: bool = True
    source_url: str

class RecommendationsResponse(BaseModel):
    status: str = "success"
    person_id: str
    person_name: str
    recommendations: List[RankedStockItem]

# Stock-Centric Ranked Figures (주식 중심 -> 연관 인물/테마 역추적 리스트)
class RankedFigureItem(BaseModel):
    rank: int
    figure_id: str
    name: str
    role_title: str
    theme_id: str
    theme_title: str
    relevance_score: float
    primary_badge: str
    depth: int
    connection_path_summary: str
    dart_fact: Optional[DartFact] = None
    source_url: str

class StockRelatedFiguresResponse(BaseModel):
    status: str = "success"
    company: Company
    micro_graph: MicroGraphResponse
    related_figures: List[RankedFigureItem]
    applied_weights: Dict[str, float]

# Combined Figure Stocks Response
class FigureRelatedStocksResponse(BaseModel):
    status: str = "success"
    figure: Person
    micro_graph: MicroGraphResponse
    recommendations: List[RankedStockItem]
    applied_weights: Dict[str, float]

# Tier 2: Investment Rationale (투자 연관성 심층 분석 텍스트)
class InvestmentRationaleReport(BaseModel):
    executive_power_analysis: str  # 임원진의 실질적 경영 실권 및 지분 지배력
    historical_market_reaction: str # 과거 동일 테마 모멘텀 발생 시 주가 반응 이력
    theme_catalyst: str            # 핵심 인물 및 정책/이벤트와의 연결 수혜 촉매

# Deep Dive Full Path Graph schemas
class GraphPathNode(BaseModel):
    id: str
    label: str
    type: NodeType
    subtitle: Optional[str] = None
    is_source: bool = False
    is_target: bool = False
    source_url: Optional[str] = None

class GraphPathEdge(BaseModel):
    source: str
    target: str
    relation_type: RelationType
    label: str
    weight: float
    dart_ref: Optional[str] = None
    source_url: Optional[str] = None

class DeepDivePathResponse(BaseModel):
    status: str = "success"
    source_person: Optional[Person] = None
    target_company: Optional[Company] = None
    relevance_score: float
    depth: int
    primary_badge: str
    dart_fact: Optional[DartFact] = None
    investment_rationale: Optional[InvestmentRationaleReport] = None
    nodes: List[GraphPathNode]
    edges: List[GraphPathEdge]

# AI Weight Baseline Models
class WeightFactorMeta(BaseModel):
    key: str
    title: str
    default_value: float
    description: str

class WeightBaselineResponse(BaseModel):
    status: str = "success"
    factors: Dict[str, WeightFactorMeta]
