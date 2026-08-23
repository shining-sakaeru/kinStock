from enum import Enum
from dataclasses import dataclass
from typing import Optional

class ThemeCategory(str, Enum):
    PRESIDENTIAL_ELECTION = "PRESIDENTIAL_ELECTION"
    GENERAL_ELECTION = "GENERAL_ELECTION"
    CABINET_POLICY = "CABINET_POLICY"
    CONGLOMERATE_GOVERNANCE = "CONGLOMERATE_GOVERNANCE"
    DIPLOMATIC_MISSION = "DIPLOMATIC_MISSION"

@dataclass(frozen=True)
class Theme:
    id: str
    code: ThemeCategory
    title: str
    short_title: str
    description: str
    icon_name: str
    badge_color: str
    figure_count: int = 0
