import math
from typing import Dict, Any, List, Optional
from enum import Enum

class PerspectiveType(str, Enum):
    COMPREHENSIVE = "COMPREHENSIVE"      # 종합 Kin-Score
    ALUMNI_FOCUSED = "ALUMNI_FOCUSED"    # 학연 집중 모드
    LEGAL_ELITE = "LEGAL_ELITE"          # 법조/정치 카르텔 모드
    REGIONAL_TIES = "REGIONAL_TIES"      # 지연/지역연고 모드
    CHAEROK_NETWORK = "CHAEROK_NETWORK"  # 재계/대기업 한솥밥 모드

class KinBondCalculator:
    """
    Person-to-Person (P2P) Multi-Dimensional Kin-Bond Scoring Engine.
    Computes precise intimacy & affinity score (0~100) based on temporal gaps,
    academic majors, exam cohorts, regional matches, and shared careers.
    """

    # Weights by Perspective Preset
    PERSPECTIVE_WEIGHTS = {
        PerspectiveType.COMPREHENSIVE: {
            "family": 0.30,
            "alumni": 0.25,
            "career": 0.25,
            "cohort": 0.15,
            "region": 0.05,
        },
        PerspectiveType.ALUMNI_FOCUSED: {
            "family": 0.05,
            "alumni": 0.70,
            "career": 0.15,
            "cohort": 0.05,
            "region": 0.05,
        },
        PerspectiveType.LEGAL_ELITE: {
            "family": 0.05,
            "alumni": 0.10,
            "career": 0.05,
            "cohort": 0.75,
            "region": 0.05,
        },
        PerspectiveType.REGIONAL_TIES: {
            "family": 0.10,
            "alumni": 0.15,
            "career": 0.10,
            "cohort": 0.05,
            "region": 0.60,
        },
        PerspectiveType.CHAEROK_NETWORK: {
            "family": 0.05,
            "alumni": 0.15,
            "career": 0.70,
            "cohort": 0.05,
            "region": 0.05,
        },
    }

    @classmethod
    def calculate_alumni_score(
        cls,
        school_type: str,
        delta_years: int,
        same_major: bool = False,
    ) -> float:
        """
        1) 학연 시간차 감가 수식 (Cohort / Seniority Decay)
        - 동기 (delta_years == 0): 고교 0.90, 대학 0.85
        - 선후배: BaseWeight * exp(-0.15 * |delta_years|)
        - 전공 일치: +0.15 가산 (Max 1.0)
        """
        base_weight = 0.90 if school_type.upper() in ["HIGH", "HIGH_SCHOOL"] else 0.85
        abs_gap = abs(delta_years)

        if abs_gap == 0:
            score = base_weight
        else:
            score = base_weight * math.exp(-0.15 * abs_gap)

        if same_major:
            score = min(1.0, score + 0.15)

        return round(score, 4)

    @classmethod
    def calculate_judicial_cohort_score(cls, delta_cohorts: int) -> float:
        """
        2) 사법연수원 / 고시 기수 결속도
        - 동기 (delta_cohorts == 0): 0.95
        - 선후배: 0.80 * exp(-0.20 * |delta_cohorts|)
        """
        abs_gap = abs(delta_cohorts)
        if abs_gap == 0:
            return 0.95
        return round(0.80 * math.exp(-0.20 * abs_gap), 4)

    @classmethod
    def calculate_career_overlap_score(cls, overlap_years: int) -> float:
        """
        3) 경력 동료 시기 중복도 (Tenure Overlap)
        - OverlapScore = min(1.0, 0.40 + (0.15 * overlap_years))
        """
        if overlap_years <= 0:
            return 0.30
        return round(min(1.0, 0.40 + (0.15 * overlap_years)), 4)

    @classmethod
    def calculate_hometown_score(cls, match_depth: str) -> float:
        """
        지연 일치 점수
        - DISTRICT (구/군 단위 일치): 0.90
        - PROVINCE (시/도 단위 일치): 0.60
        """
        return 0.90 if match_depth.upper() == "DISTRICT" else 0.60

    @classmethod
    def calculate_family_score(cls, degree_of_kinship: int) -> float:
        """
        혈연/인척 점수
        - 직계 1촌: 1.0
        - 2촌(형제): 0.95
        - 3~4촌(친인척): 0.85
        - 인척/기타: 0.70
        """
        if degree_of_kinship <= 1:
            return 1.0
        elif degree_of_kinship == 2:
            return 0.95
        elif degree_of_kinship <= 4:
            return 0.85
        return 0.70

    @classmethod
    def calculate_p2p_kin_bond(
        cls,
        factors: Dict[str, Any],
        perspective: PerspectiveType = PerspectiveType.COMPREHENSIVE,
        max_seniority_gap: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        4) 다중 시냅스 시너지(Synergy Multiplier) 및 종합 결속도(0~100) 산출
        """
        weights = cls.PERSPECTIVE_WEIGHTS.get(perspective, cls.PERSPECTIVE_WEIGHTS[PerspectiveType.COMPREHENSIVE])

        radar_scores = {
            "family": 0.0,
            "alumni": 0.0,
            "career": 0.0,
            "cohort": 0.0,
            "region": 0.0,
        }
        badges: List[str] = []
        active_factor_scores: List[float] = []

        # 1. Family Factor
        if "family" in factors:
            fam = factors["family"]
            score = cls.calculate_family_score(fam.get("degree_of_kinship", 2))
            radar_scores["family"] = score
            active_factor_scores.append(score)
            badges.append(f"👑 친인척 ({fam.get('relation_label', '친족')})")

        # 2. Alumni Factor
        if "alumni" in factors:
            alm = factors["alumni"]
            gap = alm.get("delta_years", 0)
            if max_seniority_gap is None or abs(gap) <= max_seniority_gap:
                score = cls.calculate_alumni_score(
                    school_type=alm.get("school_type", "UNIV"),
                    delta_years=gap,
                    same_major=alm.get("same_major", False),
                )
                radar_scores["alumni"] = score
                active_factor_scores.append(score)
                s_name = alm.get("school_name", "학교")
                if gap == 0:
                    badges.append(f"🟢 [{s_name} {alm.get('cohort', '')} 동기]")
                elif gap > 0:
                    badges.append(f"🔵 [{s_name} {gap}년 선배]")
                else:
                    badges.append(f"🔵 [{s_name} {abs(gap)}년 후배]")

        # 3. Career Factor
        if "career" in factors:
            car = factors["career"]
            overlap_yrs = car.get("overlap_years", 1)
            score = cls.calculate_career_overlap_score(overlap_yrs)
            radar_scores["career"] = score
            active_factor_scores.append(score)
            badges.append(f"🤝 [{car.get('company_name', '기업')} {overlap_yrs}년 공동 재직]")

        # 4. Cohort Factor (사법연수원/고시)
        if "cohort" in factors:
            coh = factors["cohort"]
            delta_c = coh.get("delta_cohorts", 0)
            score = cls.calculate_judicial_cohort_score(delta_c)
            radar_scores["cohort"] = score
            active_factor_scores.append(score)
            c_num = coh.get("cohort_num", "고시")
            if delta_c == 0:
                badges.append(f"🟣 [사법연수원 {c_num}기 동기]")
            else:
                badges.append(f"🟣 [사법연수원 {c_num}기 ({delta_c:+d}기)]")

        # 5. Region Factor (지연)
        if "region" in factors:
            reg = factors["region"]
            match_depth = reg.get("match_depth", "PROVINCE")
            score = cls.calculate_hometown_score(match_depth)
            radar_scores["region"] = score
            active_factor_scores.append(score)
            badges.append(f"🟠 [{reg.get('region_name', '고향')} 동향]")

        # Multi-Synapse Synergy Independence Combination Model
        # CompositeScore = 1 - ∏(1 - FactorScore_i) * (1 + 0.1 * (N_connections - 1))
        if not active_factor_scores:
            composite_score = 0.0
        else:
            product = 1.0
            for s in active_factor_scores:
                product *= (1.0 - s)
            base_composite = 1.0 - product
            synergy_multiplier = 1.0 + 0.10 * (len(active_factor_scores) - 1)
            composite_score = min(1.0, base_composite * synergy_multiplier)

        # Apply Perspective Weight Matrix
        weighted_sum = sum(radar_scores[k] * weights[k] for k in radar_scores)
        final_score = round(((composite_score * 0.5) + (weighted_sum * 0.5)) * 100, 1)

        return {
            "final_score": final_score,
            "perspective": perspective.value,
            "radar_scores": {k: round(v * 100, 1) for k, v in radar_scores.items()},
            "connection_count": len(active_factor_scores),
            "badges": badges,
        }

kin_bond_calculator = KinBondCalculator()
