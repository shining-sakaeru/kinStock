from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from app.data.dtos.common_dtos import MicroGraphDto
from app.data.dtos.stock_dtos import RankedStockItemDto

class PersonDto(BaseModel):
    id: str
    name: str
    category: str
    role_title: str
    theme_id: str
    hometown: Optional[str] = None
    alma_mater: List[str] = []
    cohort_info: Optional[str] = None
    key_summary: Optional[str] = None
    source_url: str

class FigureStocksResponseDto(BaseModel):
    status: str = "success"
    figure: PersonDto
    micro_graph: MicroGraphDto
    recommendations: List[RankedStockItemDto]
    applied_weights: Optional[Dict[str, float]] = None
