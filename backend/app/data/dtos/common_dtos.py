from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

class DartFactDto(BaseModel):
    report_title: str
    report_code: str
    rcp_no: str
    filing_date: str
    verified_fact: str
    source_url: str

class RadialNodeDto(BaseModel):
    node_id: str
    node_name: str
    node_type: str # PERSON or COMPANY
    relation_type: str
    relation_badge: str
    weight: float
    detail_info: Optional[str] = None
    connected_company_count: int = 0
    dart_ref: Optional[str] = None
    source_url: Optional[str] = None

class MicroGraphDto(BaseModel):
    status: str = "success"
    center_person: Optional[Any] = None
    center_company: Optional[Any] = None
    radial_nodes: List[RadialNodeDto] = []

class InvestmentRationaleDto(BaseModel):
    executive_power_analysis: str
    historical_market_reaction: str
    theme_catalyst: str

class WeightFactorDto(BaseModel):
    key: str
    title: str
    default_value: float
    description: str

class WeightBaselineDto(BaseModel):
    status: str = "success"
    factors: Dict[str, WeightFactorDto]
