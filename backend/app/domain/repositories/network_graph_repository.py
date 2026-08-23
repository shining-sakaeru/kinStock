from abc import ABC, abstractmethod
from typing import List, Tuple, Any
from app.domain.entities.relationship import NetworkPath, NetworkEdge

class NetworkGraphRepository(ABC):
    @abstractmethod
    def find_all_simple_paths(self, source_id: str, target_id: str, max_depth: int = 3) -> List[List[str]]:
        pass

    @abstractmethod
    def get_edge(self, u: str, v: str) -> NetworkEdge:
        pass

    @abstractmethod
    def get_outgoing_neighbors(self, node_id: str) -> List[Tuple[str, NetworkEdge]]:
        pass

    @abstractmethod
    def get_incoming_neighbors(self, node_id: str) -> List[Tuple[str, NetworkEdge]]:
        pass
