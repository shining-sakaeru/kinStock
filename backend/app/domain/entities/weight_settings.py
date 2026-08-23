from dataclasses import dataclass
from typing import Dict, Any

AI_DEFAULT_WEIGHTS: Dict[str, float] = {
    "executive_family": 0.95,   # 직무 실권 및 최대주주 (대표이사/사내이사 가중치 1.3배 보정)
    "exclusive_cohort": 0.85,   # 폐쇄형 엘리트 네트워크 (사법연수원, 행정고시)
    "direct_alumni": 0.70,      # 직접 학연 (동일 고교, 동일 대학 학과)
    "regional_ties": 0.45,      # 지연/동향 (동일 출신지)
    "decay_factor": 0.60        # 2-Depth 이상 다단계 감가율
}

@dataclass(frozen=True)
class WeightFactorMeta:
    key: str
    title: str
    default_value: float
    description: str

@dataclass(frozen=True)
class WeightSettings:
    executive_family: float = 0.95
    exclusive_cohort: float = 0.85
    direct_alumni: float = 0.70
    regional_ties: float = 0.45
    decay_factor: float = 0.60

    @classmethod
    def default(cls) -> "WeightSettings":
        return cls()

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "WeightSettings":
        return cls(
            executive_family=float(data.get("executive_family", 0.95)),
            exclusive_cohort=float(data.get("exclusive_cohort", 0.85)),
            direct_alumni=float(data.get("direct_alumni", 0.70)),
            regional_ties=float(data.get("regional_ties", 0.45)),
            decay_factor=float(data.get("decay_factor", 0.60))
        )

    def to_dict(self) -> Dict[str, float]:
        return {
            "executive_family": self.executive_family,
            "exclusive_cohort": self.exclusive_cohort,
            "direct_alumni": self.direct_alumni,
            "regional_ties": self.regional_ties,
            "decay_factor": self.decay_factor
        }

    def resolve_factor_weight(self, relation_type: str) -> float:
        mapping = {
            "CEO_OR_EXECUTIVE": self.executive_family,
            "MAJOR_SHAREHOLDER": self.executive_family,
            "FAMILY_RELATIVE": self.executive_family,
            "JUDICIAL_EXAM_COHORT": self.exclusive_cohort,
            "CIVIL_EXAM_COHORT": self.exclusive_cohort,
            "HIGH_SCHOOL_ALUMNI": self.direct_alumni,
            "UNIVERSITY_ALUMNI": self.direct_alumni,
            "HOMETOWN_FRIEND": self.regional_ties,
            "POLITICAL_CAMP": self.exclusive_cohort,
            "POLICY_THEME": self.executive_family,
            "DIPLOMATIC_DELEGATION": self.exclusive_cohort,
            "OUTSIDE_DIRECTOR": self.executive_family * 0.85,
        }
        return mapping.get(relation_type, self.regional_ties)
