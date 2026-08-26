from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from app.data.dtos.common_dtos import MicroGraphDto, DartFactDto

class CompanyDto(BaseModel):
    id: str
    ticker: str
    name: str
    industry: str
    current_price: float
    price_change_rate: float
    market_cap: str
    dart_corp_code: Optional[str] = None
    source_url: str

class RankedStockItemDto(BaseModel):
    rank: int
    company_id: str
    ticker: str
    company_name: str
    relevance_score: float
    primary_badge: str
    current_price: float
    price_change_rate: float
    market_cap: str
    industry: str
    depth: int = 1
    connection_path_summary: str
    dart_fact: Optional[DartFactDto] = None
    is_dart_verified: bool = True
    source_url: str

class RankedFigureItemDto(BaseModel):
    rank: int
    figure_id: str
    name: str
    role_title: str
    theme_id: str
    theme_title: str
    relevance_score: float
    primary_badge: str
    depth: int = 1
    connection_path_summary: str
    dart_fact: Optional[DartFactDto] = None
    source_url: str

class StockFiguresResponseDto(BaseModel):
    status: str = "success"
    company: CompanyDto
    micro_graph: MicroGraphDto
    related_figures: List[RankedFigureItemDto]
    applied_weights: Optional[Dict[str, float]] = None
