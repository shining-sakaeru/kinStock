from enum import Enum
from datetime import datetime, timezone
from typing import Optional
from pydantic import BaseModel, Field

class SourceTier(str, Enum):
    TIER_1_LEGAL = "TIER_1_LEGAL"     # 법적 구속력 있는 전자공시 (DART, KIND)
    TIER_2_PUBLIC = "TIER_2_PUBLIC"   # 공공기관 검증 데이터 (공공데이터포털, KLCA)
    TIER_3_NEWS = "TIER_3_NEWS"       # 보완 및 언론 데이터 (빅카인즈, 네이버 금융)

class SourceName(str, Enum):
    DART = "DART"
    KIND = "KIND"
    DATA_GO_KR = "DATA_GO_KR"
    BIG_KINDS = "BIG_KINDS"
    NAVER_FINANCE = "NAVER_FINANCE"

class EvidenceMeta(BaseModel):
    """
    Standardized Evidence and Provenance Metadata for every Node & Edge.
    Enforces clear separation of legal disclosure facts from news supplements.
    """
    source_tier: SourceTier = Field(
        default=SourceTier.TIER_1_LEGAL,
        description="데이터 신뢰도 등급 (TIER_1_LEGAL, TIER_2_PUBLIC, TIER_3_NEWS)"
    )
    source_name: SourceName = Field(
        default=SourceName.DART,
        description="데이터 소스 명칭"
    )
    source_ref_id: str = Field(
        ...,
        description="공시 접수번호 (rcept_no 14자리) 또는 문서/기사 고유 ID"
    )
    evidence_text: str = Field(
        ...,
        description="팩트 판단의 근거가 된 공시/문서 원문 발췌 문장"
    )
    source_url: str = Field(
        ...,
        description="해당 공시/문서의 웹 뷰어 다이렉트 링크"
    )
    verified_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat(),
        description="검증 및 데이터 적재 타임스탬프 (ISO 8601)"
    )

    @property
    def badge_label(self) -> str:
        if self.source_tier == SourceTier.TIER_1_LEGAL:
            return "🟢 공시 팩트"
        elif self.source_tier == SourceTier.TIER_2_PUBLIC:
            return "🔵 공공 검증"
        return "🟡 언론 보도"
