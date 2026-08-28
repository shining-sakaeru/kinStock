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

class ProvenanceType(str, Enum):
    DIRECT_DART_FACT = "DIRECT_DART_FACT"       # DART 명시적 공시 사실 (지분, 임원 등재)
    INFERRED_SYNAPSE = "INFERRED_SYNAPSE"       # 복수 데이터 교차 추론 (지연/학연 교집합)
    OFFICIAL_PRESS_FACT = "OFFICIAL_PRESS_FACT" # 공식 발표/언론 팩트 (출마선언지, 포럼 참여)

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
    provenance_type: ProvenanceType = ProvenanceType.DIRECT_DART_FACT
    provenance_badge: str = "🟢 [DART 100% 팩트]"
    provenance_explanation: str = "DART 정기보고서 원문에 임원 및 지분이 명시 기재된 법적 확인 팩트입니다."
    rcept_no: str = ""
    report_name: str = "2024.03 사업보고서"
    section: str = "VIII. 임원 및 직원 등에 관한 사항"
    snippet: str = ""
    source_url: str = "" # Official DART Portal or Verified URL
    person_proof_url: Optional[str] = None # Direct Person Profile URL
    fact_news_url: Optional[str] = None    # Direct News/Historical Proof URL
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
