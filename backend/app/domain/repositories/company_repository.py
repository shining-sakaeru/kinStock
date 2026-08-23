from abc import ABC, abstractmethod
from typing import List, Optional
from app.domain.entities.company import Company

class CompanyRepository(ABC):
    @abstractmethod
    def get_all_companies(self) -> List[Company]:
        pass

    @abstractmethod
    def get_company_by_id_or_ticker(self, id_or_ticker: str) -> Optional[Company]:
        pass

    @abstractmethod
    def search_companies(self, query: str, limit: int = 10) -> List[Company]:
        pass
