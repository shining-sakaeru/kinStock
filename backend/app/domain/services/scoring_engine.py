import math
from typing import List, Optional, Tuple
from app.domain.entities.relationship import NetworkEdge
from app.domain.entities.weight_settings import WeightSettings

def calculate_single_path_score(
    edges: List[NetworkEdge],
    weights: WeightSettings
) -> float:
    """
    순수 함수: 단일 경로(Path)의 지수 감가 가중치 점수를 계산합니다.
    Score = (Prod(edge_weight) * direct_correction) * (decay_factor)^(length - 1)
    """
    if not edges:
        return 0.0

    accumulated = 1.0
    for edge in edges:
        w = weights.resolve_factor_weight(edge.relation_type.value)
        # CEO/대주주 1.3배 직무 실권 보정
        if edge.relation_type.value in ["CEO_OR_EXECUTIVE", "MAJOR_SHAREHOLDER"]:
            w = min(1.0, w * 1.3)
        accumulated *= w

    decay = weights.decay_factor ** (len(edges) - 1)
    return accumulated * decay

def calculate_aggregated_relevance(
    path_scores: List[float]
) -> float:
    """
    순수 함수: 다중 경로 결합 연관도 누적 점수 (0 ~ 100점).
    Relevance = 100 * (1 - Prod(1 - Score_k))
    """
    if not path_scores:
        return 0.0

    unconnected_prob = 1.0
    for score in path_scores:
        clamped = max(0.0, min(1.0, score))
        unconnected_prob *= (1.0 - clamped)

    total_score = (1.0 - unconnected_prob) * 100.0
    return round(total_score, 1)

def format_path_summary(
    person_name: str,
    intermediate_name: Optional[str],
    company_name: str,
    badges: List[str],
    hops: int
) -> Tuple[str, str]:
    """
    순수 함수: 경로 요약 뱃지 및 한 줄 DART 공시 요약문 생성.
    """
    if hops == 1 and badges:
        badge = badges[0]
        summary = f"[DART 공시] {person_name} ➔ {company_name} ({badges[0]})"
    elif hops > 1 and badges:
        badge = f"{badges[0]} ➔ {badges[-1]}"
        inter = intermediate_name or "지인"
        summary = f"[DART 공시] {inter}({badges[0]}) ➔ {company_name}({badges[-1]})"
    else:
        badge = "연관"
        summary = f"[DART 공시] {person_name} ➔ {company_name} 네트워크 연관"

    return badge, summary
