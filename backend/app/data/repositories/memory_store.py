import networkx as nx
from typing import List, Optional, Dict, Tuple
from app.domain.entities.person import Person, PersonCategory
from app.domain.entities.company import Company
from app.domain.entities.theme import Theme, ThemeCategory
from app.domain.entities.relationship import RelationType, NetworkEdge, RELATION_METADATA
from app.domain.repositories.person_repository import PersonRepository
from app.domain.repositories.company_repository import CompanyRepository
from app.domain.repositories.theme_repository import ThemeRepository
from app.domain.repositories.network_graph_repository import NetworkGraphRepository
from app.data.repositories.korea_stock_universe import build_complete_stock_universe

class InMemoryGraphStore(PersonRepository, CompanyRepository, ThemeRepository, NetworkGraphRepository):
    def __init__(self):
        self.graph = nx.DiGraph()
        self.themes: Dict[str, Theme] = {}
        self.persons: Dict[str, Person] = {}
        self.companies: Dict[str, Company] = {}
        self._init_seed_data()

    def _init_seed_data(self):
        # 1. 5 Core Preset Themes
        themes_data = [
            Theme(id="theme_presidential", code=ThemeCategory.PRESIDENTIAL_ELECTION, title="대선 테마", short_title="대선", description="유력 대권 주자 및 싱크탱크·참모진 네트워크", icon_name="how_to_vote", badge_color="#0A84FF"),
            Theme(id="theme_general_election", code=ThemeCategory.GENERAL_ELECTION, title="총선/보선 테마", short_title="총선/보선", description="여야 지도부 및 격전지 핵심 의원 라인", icon_name="account_balance", badge_color="#64D2FF"),
            Theme(id="theme_cabinet_policy", code=ThemeCategory.CABINET_POLICY, title="내각/정책 테마", short_title="내각/정책", description="경제부총리·금융당국 밸류업 및 정책 수혜", icon_name="policy", badge_color="#FF9F0A"),
            Theme(id="theme_conglomerate", code=ThemeCategory.CONGLOMERATE_GOVERNANCE, title="대기업 지배구조·승계", short_title="지배구조", description="삼성·현대차·신세계 오너 일가 및 지주사 지분 승계", icon_name="corporate_fare", badge_color="#BF5AF2"),
            Theme(id="theme_diplomacy", code=ThemeCategory.DIPLOMATIC_MISSION, title="특사단·글로벌 외교", short_title="외교/특사단", description="K-방산·원전·신재생 글로벌 경제사절단 및 통상 특사", icon_name="public", badge_color="#30D158"),
        ]
        for t in themes_data:
            self.themes[t.id] = t

        # 2. Complete Universe Generation (1,124+ Companies, Key Persons & Network Edges)
        companies, persons, edges = build_complete_stock_universe()

        for p in persons:
            self.persons[p.id] = p
            self.graph.add_node(p.id, type="PERSON", data=p)

        for c in companies:
            self.companies[c.id] = c
            self.graph.add_node(c.id, type="COMPANY", data=c)

        for u, v, rel_type, badge, weight, source_url in edges:
            meta = RELATION_METADATA.get(rel_type, {"tier": 3, "score": 70, "label": "일반 연계"})
            edge_obj = NetworkEdge(
                source_id=u,
                target_id=v,
                relation_type=rel_type,
                label=badge,
                badge=badge,
                base_weight=weight,
                source_url=source_url
            )
            self.graph.add_edge(u, v, edge=edge_obj, type=rel_type.value, badge=badge, weight=weight, source_url=source_url)
            self.graph.add_edge(v, u, edge=edge_obj, type=rel_type.value, badge=badge, weight=weight, source_url=source_url)

    # ---------------- PersonRepository Implementation ----------------
    def get_all_persons(self) -> List[Person]:
        return list(self.persons.values())

    def get_person_by_id(self, person_id: str) -> Optional[Person]:
        if person_id in self.persons:
            return self.persons[person_id]
        clean_id = person_id[2:] if person_id.startswith("P_") else f"P_{person_id}"
        if clean_id in self.persons:
            return self.persons[clean_id]
        for pid, p in self.persons.items():
            if person_id in pid or p.name == person_id or person_id in p.name:
                return p
        return None

    def get_persons_by_theme(self, theme_id: str) -> List[Person]:
        return [p for p in self.persons.values() if p.theme_id == theme_id]

    def search_persons(self, query: str, limit: int = 20) -> List[Person]:
        q = query.lower().strip()
        matches = [
            p for p in self.persons.values()
            if q in p.name.lower() or q in p.role_title.lower() or any(q in a.lower() for a in p.alma_mater) or (p.cohort_info and q in p.cohort_info.lower()) or (p.key_summary and q in p.key_summary.lower())
        ]
        return matches[:limit]

    # ---------------- CompanyRepository Implementation ----------------
    def get_all_companies(self) -> List[Company]:
        return list(self.companies.values())

    def get_company_by_id(self, company_id: str) -> Optional[Company]:
        return self.companies.get(company_id)

    def get_company_by_id_or_ticker(self, id_or_ticker: str) -> Optional[Company]:
        if id_or_ticker in self.companies:
            return self.companies[id_or_ticker]
        c_id = f"C_{id_or_ticker}" if not id_or_ticker.startswith("C_") else id_or_ticker
        if c_id in self.companies:
            return self.companies[c_id]
        for cid, c in self.companies.items():
            if c.ticker == id_or_ticker or c.name == id_or_ticker or c.dart_corp_code == id_or_ticker:
                return c
        return None

    def search_companies(self, query: str, limit: int = 30) -> List[Company]:
        q = query.lower().strip()
        matches = [
            c for c in self.companies.values()
            if q in c.name.lower() or q in c.ticker.lower() or q in c.industry.lower()
        ]
        return matches[:limit]

    # ---------------- ThemeRepository Implementation ----------------
    def get_all_themes(self) -> List[Theme]:
        res = []
        for t in self.themes.values():
            count = sum(1 for p in self.persons.values() if p.theme_id == t.id)
            res.append(Theme(
                id=t.id,
                code=t.code,
                title=t.title,
                short_title=t.short_title,
                description=t.description,
                icon_name=t.icon_name,
                badge_color=t.badge_color,
                figure_count=count
            ))
        return res

    def get_theme_by_id(self, theme_id: str) -> Optional[Theme]:
        t = self.themes.get(theme_id)
        if t:
            count = sum(1 for p in self.persons.values() if p.theme_id == t.id)
            return Theme(
                id=t.id,
                code=t.code,
                title=t.title,
                short_title=t.short_title,
                description=t.description,
                icon_name=t.icon_name,
                badge_color=t.badge_color,
                figure_count=count
            )
        return None

    def search_themes(self, query: str, limit: int = 10) -> List[Theme]:
        q = query.lower().strip()
        matches = [
            t for t in self.themes.values()
            if q in t.title.lower() or q in t.short_title.lower() or q in t.description.lower()
        ]
        return matches[:limit]

    # ---------------- NetworkGraphRepository Implementation ----------------
    def find_all_simple_paths(self, source_id: str, target_id: str, max_depth: int = 3) -> List[List[str]]:
        if source_id not in self.graph or target_id not in self.graph:
            return []
        try:
            results = []
            for path in nx.all_simple_paths(self.graph, source=source_id, target=target_id, cutoff=max_depth):
                results.append(path)
                if len(results) >= 10:
                    break
            return results
        except (nx.NetworkXNoPath, nx.NodeNotFound):
            return []

    def get_edge(self, u: str, v: str) -> NetworkEdge:
        if u in self.graph and v in self.graph[u] and "edge" in self.graph[u][v]:
            return self.graph[u][v]["edge"]
        return NetworkEdge(source_id=u, target_id=v, relation_type=RelationType.POLICY_THEME, badge_name="연계", weight=0.5)

    def get_outgoing_neighbors(self, node_id: str) -> List[Tuple[str, NetworkEdge]]:
        if node_id not in self.graph:
            return []
        res = []
        for v in self.graph.successors(node_id):
            edge = self.graph[node_id][v].get("edge") or NetworkEdge(source_id=node_id, target_id=v, relation_type=RelationType.POLICY_THEME, badge_name="연계", weight=0.5)
            res.append((v, edge))
        return res

    def get_incoming_neighbors(self, node_id: str) -> List[Tuple[str, NetworkEdge]]:
        if node_id not in self.graph:
            return []
        res = []
        for u in self.graph.predecessors(node_id):
            edge = self.graph[u][node_id].get("edge") or NetworkEdge(source_id=u, target_id=node_id, relation_type=RelationType.POLICY_THEME, badge_name="연계", weight=0.5)
            res.append((u, edge))
        return res

    def get_neighbors(self, node_id: str, depth: int = 1) -> List[NetworkEdge]:
        edges: List[NetworkEdge] = []
        if node_id not in self.graph:
            return edges
        
        visited = {node_id}
        current_layer = [node_id]

        for current_depth in range(1, depth + 1):
            next_layer = []
            for curr in current_layer:
                for neighbor in self.graph.neighbors(curr):
                    if neighbor not in visited:
                        visited.add(neighbor)
                        next_layer.append(neighbor)
                        edge_data = self.graph.get_edge_data(curr, neighbor)
                        rel_type_str = edge_data.get("type", "CONNECTED_WITH")
                        try:
                            rel_type = RelationType(rel_type_str)
                        except ValueError:
                            rel_type = RelationType.POLICY_THEME

                        meta = RELATION_METADATA.get(rel_type, {"tier": 3, "score": 70, "label": "일반 연계"})
                        edges.append(NetworkEdge(
                            source_id=curr,
                            target_id=neighbor,
                            relation_type=rel_type,
                            label=edge_data.get("badge", meta["label"]),
                            badge=edge_data.get("badge", meta["label"]),
                            base_weight=edge_data.get("weight", 0.5),
                            source_url=edge_data.get("source_url", "")
                        ))
            current_layer = next_layer
        return edges

    def get_shortest_path(self, start_id: str, end_id: str) -> Optional[List[str]]:
        try:
            return nx.shortest_path(self.graph, source=start_id, target=end_id)
        except (nx.NetworkXNoPath, nx.NodeNotFound):
            return None

memory_store = InMemoryGraphStore()
