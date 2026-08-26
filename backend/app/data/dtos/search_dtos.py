from pydantic import BaseModel
from typing import List, Optional
from enum import Enum

class SearchCategory(str, Enum):
    PERSON = "PERSON"
    STOCK = "STOCK"
    THEME = "THEME"

class SearchItemDto(BaseModel):
    id: str
    type: SearchCategory # PERSON, STOCK, THEME
    title: str
    subtitle: str
    badge: str
    target_id: str
    source_url: Optional[str] = None

class SearchUniversalResponseDto(BaseModel):
    status: str = "success"
    query: str
    total_count: int
    results: List[SearchItemDto]
