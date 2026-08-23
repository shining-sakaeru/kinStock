from abc import ABC, abstractmethod
from typing import List, Optional
from app.domain.entities.theme import Theme

class ThemeRepository(ABC):
    @abstractmethod
    def get_all_themes(self) -> List[Theme]:
        pass

    @abstractmethod
    def get_theme_by_id(self, theme_id: str) -> Optional[Theme]:
        pass

    @abstractmethod
    def search_themes(self, query: str, limit: int = 10) -> List[Theme]:
        pass
