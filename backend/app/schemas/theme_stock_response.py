from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from enum import Enum

class ThemeTier(str, Enum):
    LEADER = "LEADER"      # 🔥 1티어 대장주 (< 1000억)
    BENEFICIARY = "BENEFICIARY" # ⚡ 2티어 수혜주 (1000억~3000억)
    FOLLOWER = "FOLLOWER"  # 🔹 3티어 후발주 (> 3000억)

class CausalChainNode(BaseModel):
    id: str
    name: str
    type: str # PERSON, COMPANY
    role_or_title: str
    extra_info: Optional[str] = None

class CausalChainEdge(BaseModel):
    from_id: str
    to_id: str
    relation_label: str
    badge: str
    evidence_text: str
    weight: float

class CausalPathChain(BaseModel):
    source_person: CausalChainNode
    p2p_edge: CausalChainEdge
    intermediary_person: CausalChainNode
    p2c_edge: CausalChainEdge
    target_company: CausalChainNode

class AuditFactEvidence(BaseModel):
    dart_filing_title: str
    rcp_no: str
    filing_date: str
    verified_fact: str
    dart_url: str
    market_track_record: str

class ThemeTradingMetrics(BaseModel):
    market_cap_str: str
    current_price: int
    price_change_rate: float
    major_shareholder_ratio: float
    floating_ratio: float

class ThemeStockRankItem(BaseModel):
    rank: int
    ticker: str
    company_name: str
    industry: str
    kin_score: float # 0~100
    theme_tier: ThemeTier
    theme_tier_label: str
    
    # 3-Depth Causal Reasoning
    depth1_hook: str                    # Depth 1: One-line hook
    depth2_causal_chain: CausalPathChain # Depth 2: 3-step causal chain
    depth3_evidence: AuditFactEvidence   # Depth 3: DART filing & market track record
    
    trading_metrics: ThemeTradingMetrics

class PersonThemeStocksResponse(BaseModel):
    status: str
    person_id: str
    person_name: str
    person_title: str
    person_alma_mater: List[str]
    person_cohort: str
    person_hometown: str
    total_stocks_count: int
    avg_kin_score: float
    stocks: List[ThemeStockRankItem]
