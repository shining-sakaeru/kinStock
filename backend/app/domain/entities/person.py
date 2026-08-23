from enum import Enum
from dataclasses import dataclass, field
from typing import Optional, List

class PersonCategory(str, Enum):
    POLITICIAN = "POLITICIAN"
    PUBLIC_OFFICIAL = "PUBLIC_OFFICIAL"
    BUSINESSMAN = "BUSINESSMAN"
    LAWYER_PROFESSOR = "LAWYER_PROFESSOR"

@dataclass(frozen=True)
class Person:
    id: str
    name: str
    category: PersonCategory
    role_title: str
    theme_id: str = "theme_presidential"
    hometown: Optional[str] = None
    alma_mater: List[str] = field(default_factory=list)
    cohort_info: Optional[str] = None
    key_summary: Optional[str] = None
    source_url: str = "https://open.assembly.go.kr"
