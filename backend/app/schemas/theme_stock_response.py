from typing import List, Optional, Dict, Any, Union
from pydantic import BaseModel, Field
from enum import Enum

class RoleTier(str, Enum):
    PRIMARY_ANCHOR = "PRIMARY_ANCHOR"   # 👑 1티어 대장주
    DIRECT_PROXY = "DIRECT_PROXY"       # ⚡ 2티어 직결 수혜주
    NEXUS_BRIDGE = "NEXUS_BRIDGE"       # 🔗 3티어 매개주
    SYMPATHY_FRINGE = "SYMPATHY_FRINGE" # 💨 4티어 후발주

class FactorGrade(str, Enum):
    A_PLUS = "A+"
    A = "A"
    B = "B"
    C = "C"

class ConvictionLevel(str, Enum):
    HIGH = "HIGH"
    MODERATE = "MODERATE"
    SPECULATIVE = "SPECULATIVE"

class CausalMetrics(BaseModel):
    role_tier: RoleTier
    role_tier_label: str
    degree_of_sep: int # 1, 2, 3
    degree_label: str  # "1-Degree Direct (1촌 직결)"
    factor_grade: FactorGrade
    factor_grade_label: str
    conviction_level: ConvictionLevel
    conviction_label: str
    causal_equation: str # "[사법연수원 14기 동기 (A+)] ✕ [대표이사 경영권 장악 (지분 24.5%)]"

class CausalPathStep(BaseModel):
    type: str # "PERSON", "EDGE", "COMPANY"
    name: Optional[str] = None
    role: Optional[str] = None
    ticker: Optional[str] = None
    label: Optional[str] = None
    grade: Optional[str] = None
    delta_years: Optional[int] = None
    influence: Optional[str] = None
    stake_ratio: Optional[float] = None

class AuditFactEvidenceV2(BaseModel):
    source_name: str = "DART"
    rcept_no: str
    report_name: str
    section: str
    snippet: str
    source_url: str
    market_track_record: Optional[str] = None

class CausalChainV2(BaseModel):
    depth_1_hook: str
    depth_2_path: List[CausalPathStep]
    depth_3_evidence: AuditFactEvidenceV2

class ThemeStockItemV2(BaseModel):
    rank: int
    stock_code: str
    stock_name: str
    industry: str
    market_cap: str
    current_price: int
    price_change_rate: float
    kin_score: float # 0~100
    metrics: CausalMetrics
    causal_chain: CausalChainV2

class ThemeStocksApiResponse(BaseModel):
    status: str
    person_id: str
    person_name: str
    person_title: str
    person_alma_mater: List[str]
    person_cohort: str
    person_hometown: str
    total_stocks_count: int
    avg_kin_score: float
    stocks: List[ThemeStockItemV2]
