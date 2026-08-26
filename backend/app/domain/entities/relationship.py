from enum import Enum
from dataclasses import dataclass
from typing import Optional, List

class RelationType(str, Enum):
    CEO_OR_EXECUTIVE = "CEO_OR_EXECUTIVE"
    MAJOR_SHAREHOLDER = "MAJOR_SHAREHOLDER"
    OUTSIDE_DIRECTOR = "OUTSIDE_DIRECTOR"
    HIGH_SCHOOL_ALUMNI = "HIGH_SCHOOL_ALUMNI"
    UNIVERSITY_ALUMNI = "UNIVERSITY_ALUMNI"
    JUDICIAL_EXAM_COHORT = "JUDICIAL_EXAM_COHORT"
    CIVIL_EXAM_COHORT = "CIVIL_EXAM_COHORT"
    POLITICAL_CAMP = "POLITICAL_CAMP"
    HOMETOWN_FRIEND = "HOMETOWN_FRIEND"
    FAMILY_RELATIVE = "FAMILY_RELATIVE"
    POLICY_THEME = "POLICY_THEME"
    DIPLOMATIC_DELEGATION = "DIPLOMATIC_DELEGATION"

RELATION_METADATA = {
    RelationType.CEO_OR_EXECUTIVE: {"weight_key": "executive_family", "default_weight": 0.95, "badge": "대표이사/사내이사", "category": "기업실권"},
    RelationType.MAJOR_SHAREHOLDER: {"weight_key": "executive_family", "default_weight": 0.95, "badge": "최대주주/오너", "category": "지배구조"},
    RelationType.OUTSIDE_DIRECTOR: {"weight_key": "executive_family", "default_weight": 0.80, "badge": "사외이사/자문", "category": "자문단"},
    RelationType.HIGH_SCHOOL_ALUMNI: {"weight_key": "direct_alumni", "default_weight": 0.70, "badge": "고교동문", "category": "학연"},
    RelationType.UNIVERSITY_ALUMNI: {"weight_key": "direct_alumni", "default_weight": 0.70, "badge": "대학동문", "category": "학연"},
    RelationType.JUDICIAL_EXAM_COHORT: {"weight_key": "exclusive_cohort", "default_weight": 0.85, "badge": "사법연수원 동기", "category": "고위인맥"},
    RelationType.CIVIL_EXAM_COHORT: {"weight_key": "exclusive_cohort", "default_weight": 0.85, "badge": "행정고시 동기", "category": "고위인맥"},
    RelationType.POLITICAL_CAMP: {"weight_key": "exclusive_cohort", "default_weight": 0.85, "badge": "선대위/참모진", "category": "정치라인"},
    RelationType.HOMETOWN_FRIEND: {"weight_key": "regional_ties", "default_weight": 0.45, "badge": "동향/지연", "category": "지연"},
    RelationType.FAMILY_RELATIVE: {"weight_key": "executive_family", "default_weight": 0.95, "badge": "친인척/혈연", "category": "혈연"},
    RelationType.POLICY_THEME: {"weight_key": "executive_family", "default_weight": 0.90, "badge": "핵심정책 수혜", "category": "정책수혜"},
    RelationType.DIPLOMATIC_DELEGATION: {"weight_key": "exclusive_cohort", "default_weight": 0.85, "badge": "특사/경제사절단", "category": "외교통상"},
}

@dataclass(frozen=True)
class NetworkEdge:
    source_id: str
    target_id: str
    relation_type: RelationType
    label: str
    badge: str
    base_weight: float
    source_url: str
    rcept_no: Optional[str] = "20240321001201"

@dataclass(frozen=True)
class NetworkPath:
    nodes: List[str]
    edges: List[NetworkEdge]
