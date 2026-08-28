from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from enum import Enum

class EventEvidenceTier(str, Enum):
    TIER_1_LEGAL = "TIER_1_LEGAL"     # 🟢 공시/선관위 공식 팩트 (HIGH)
    TIER_2_OFFICIAL = "TIER_2_OFFICIAL" # 🔵 정당/공공기관 발표
    TIER_3_MEDIA = "TIER_3_MEDIA"       # 🟠 주요 언론 보도 (SPECULATIVE)

class EventType(str, Enum):
    DECLARATION = "DECLARATION"       # 출마 선언
    PRIMARY_VICTORY = "PRIMARY_VICTORY" # 경선 승리 / 후보 확정
    PARTY_LEADERSHIP = "PARTY_LEADERSHIP" # 당대표 당선
    POLICY_LAUNCH = "POLICY_LAUNCH"   # 핵심 공약 / 정책 발표
    LEGAL_OUTCOME = "LEGAL_OUTCOME"   # 사법 판결 / 무죄 / 리스크
    UNIFICATION = "UNIFICATION"       # 후보 단일화 / 연대

# 1. Poll Survey Models
class PollCandidateScore(BaseModel):
    person_id: str
    person_name: str
    party_or_group: str
    role_title: str
    approval_rate: float
    rank: int
    delta_rate: float # Compared to previous survey (+1.5, -0.8)
    badge_color: str

class PollSurveyDto(BaseModel):
    poll_id: str
    agency: str               # 예: 한국갤럽, 리얼미터, NBS
    surveyed_at: str          # 예: 2026-08-25
    sample_size: int          # 예: 1004
    confidence_level: float   # 예: 95.0
    margin_of_error: float    # 예: 3.1
    survey_method: str        # 예: 무선 RDD 전화면접
    source_url: str
    candidates: List[PollCandidateScore]

class PollLeaderboardResponse(BaseModel):
    status: str
    latest_poll: PollSurveyDto
    leaderboard: List[PollCandidateScore]
    historical_trends: List[Dict[str, Any]] # Time-series trend per candidate

# 2. Political Event & Timeline Models
class PoliticalEventDto(BaseModel):
    event_id: str
    person_id: str
    person_name: str
    title: str
    event_type: EventType
    event_type_label: str
    occurred_at: str          # YYYY-MM-DD
    significance_score: float # 1.0 ~ 5.0 (중대성 지수)
    evidence_tier: EventEvidenceTier
    evidence_tier_badge: str  # 🟢 100% 팩트 or 🟠 언론 보도
    summary: str
    source_agency: str
    source_url: str

class PersonEventTimelineResponse(BaseModel):
    status: str
    person_id: str
    person_name: str
    total_events: int
    events: List[PoliticalEventDto]

# 3. Event-Study Stock Impact Models
class StockImpactDetail(BaseModel):
    corp_code: str
    ticker: str
    company_name: str
    role_tier: str            # PRIMARY_ANCHOR, DIRECT_PROXY, NEXUS_BRIDGE, SYMPATHY_FRINGE
    role_tier_label: str
    factor_grade: str         # A+, A, B, C
    d0_return: float          # 당일 수익률 (%)
    car_d5: float             # 누적 이상수익률 CAR[-3, +5] (%)
    volume_spike_ratio: float # 평소 20일 평균 대비 거래량 배수 (예: 4.8x)
    peak_return: float        # 윈도우 기간 내 최고 상승률 (%)
    market_reaction_grade: str# 🔥 상한가/급등, ⚡ 강세, 🔹 완만한 반응
    connection_hook: str      # 인맥 연결 요약

class EventStockImpactResponse(BaseModel):
    status: str
    event: PoliticalEventDto
    total_affected_stocks: int
    avg_d0_return: float
    avg_car_d5: float
    stocks: List[StockImpactDetail]
