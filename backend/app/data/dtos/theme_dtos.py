from pydantic import BaseModel
from typing import List, Optional
from app.data.dtos.person_dtos import PersonDto
from app.data.dtos.stock_dtos import RankedStockItemDto

class ThemeDto(BaseModel):
    id: str
    code: str
    title: str
    short_title: str
    description: str
    icon_name: str
    badge_color: str
    figure_count: int = 0

class ThemeClusterResponseDto(BaseModel):
    status: str = "success"
    theme: ThemeDto
    key_figures: List[PersonDto]
    top_theme_stocks: List[RankedStockItemDto]
