from pydantic import BaseModel
from typing import List, Optional
from app.data.dtos.person_dtos import PersonDto
from app.data.dtos.stock_dtos import CompanyDto
from app.data.dtos.common_dtos import DartFactDto, InvestmentRationaleDto

class GraphPathNodeDto(BaseModel):
    id: str
    label: str
    type: str # PERSON or COMPANY
    subtitle: Optional[str] = None
    is_source: bool = False
    is_target: bool = False
    source_url: Optional[str] = None

class GraphPathEdgeDto(BaseModel):
    source: str
    target: str
    relation_type: str
    label: str
    weight: float
    dart_ref: Optional[str] = None
    source_url: Optional[str] = None

class DeepDivePathResponseDto(BaseModel):
    status: str = "success"
    source_person: Optional[PersonDto] = None
    target_company: Optional[CompanyDto] = None
    relevance_score: float
    depth: int
    primary_badge: str
    dart_fact: Optional[DartFactDto] = None
    investment_rationale: Optional[InvestmentRationaleDto] = None
    nodes: List[GraphPathNodeDto]
    edges: List[GraphPathEdgeDto]
