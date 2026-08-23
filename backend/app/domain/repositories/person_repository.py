from abc import ABC, abstractmethod
from typing import List, Optional
from app.domain.entities.person import Person

class PersonRepository(ABC):
    @abstractmethod
    def get_all_persons(self) -> List[Person]:
        pass

    @abstractmethod
    def get_person_by_id(self, person_id: str) -> Optional[Person]:
        pass

    @abstractmethod
    def get_persons_by_theme(self, theme_id: str) -> List[Person]:
        pass

    @abstractmethod
    def search_persons(self, query: str, limit: int = 10) -> List[Person]:
        pass
