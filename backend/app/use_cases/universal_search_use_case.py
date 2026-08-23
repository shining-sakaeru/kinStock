from typing import List
from app.domain.repositories.person_repository import PersonRepository
from app.domain.repositories.company_repository import CompanyRepository
from app.domain.repositories.theme_repository import ThemeRepository
from app.data.dtos.search_dtos import SearchItemDto, SearchCategory, SearchUniversalResponseDto
from app.data.repositories.neo4j_repository import neo4j_repository

class UniversalSearchUseCase:
    def __init__(
        self,
        person_repo: PersonRepository,
        company_repo: CompanyRepository,
        theme_repo: ThemeRepository
    ):
        self.person_repo = person_repo
        self.company_repo = company_repo
        self.theme_repo = theme_repo

    def execute(self, query: str, limit: int = 10) -> SearchUniversalResponseDto:
        if not query or len(query.strip()) == 0:
            return SearchUniversalResponseDto(status="success", query="", total_count=0, results=[])

        q = query.strip()
        results: List[SearchItemDto] = []
        seen_ids = set()

        # 1. Search Themes
        themes = self.theme_repo.search_themes(q, limit=3)
        for t in themes:
            if t.id not in seen_ids:
                seen_ids.add(t.id)
                results.append(
                    SearchItemDto(
                        id=t.id,
                        type=SearchCategory.THEME,
                        title=t.title,
                        subtitle=t.description,
                        badge="테마",
                        target_id=t.id,
                        source_url=None
                    )
                )

        # 2. Search Persons (In-Memory Repository)
        persons = self.person_repo.search_persons(q, limit=5)
        for p in persons:
            if p.id not in seen_ids:
                seen_ids.add(p.id)
                results.append(
                    SearchItemDto(
                        id=p.id,
                        type=SearchCategory.PERSON,
                        title=p.name,
                        subtitle=p.role_title,
                        badge="인물",
                        target_id=p.id,
                        source_url=p.source_url
                    )
                )

        # 3. Search Companies (In-Memory Repository)
        companies = self.company_repo.search_companies(q, limit=5)
        for c in companies:
            if c.id not in seen_ids:
                seen_ids.add(c.id)
                results.append(
                    SearchItemDto(
                        id=c.id,
                        type=SearchCategory.STOCK,
                        title=c.name,
                        subtitle=f"{c.ticker} · {c.industry}",
                        badge="주식",
                        target_id=c.ticker,
                        source_url=c.source_url
                    )
                )

        # 4. Fallback Live Search directly from Neo4j DB (for newly crawled records)
        neo_corps = neo4j_repository.search_companies(q, limit=5)
        for nc in neo_corps:
            c_id = f"C_{nc.get('stock_code', nc.get('corp_code'))}"
            if c_id not in seen_ids:
                seen_ids.add(c_id)
                results.append(
                    SearchItemDto(
                        id=c_id,
                        type=SearchCategory.STOCK,
                        title=nc.get("name", ""),
                        subtitle=f"{nc.get('stock_code', '')} · {nc.get('industry', '상장기업')}",
                        badge="주식",
                        target_id=nc.get("stock_code", nc.get("corp_code", "")),
                        source_url=f"https://dart.fss.or.kr/corp/summary.do?corpCode={nc.get('corp_code', '')}"
                    )
                )

        neo_persons = neo4j_repository.search_persons(q, limit=5)
        for np in neo_persons:
            p_id = np.get("person_id", "")
            if p_id not in seen_ids:
                seen_ids.add(p_id)
                results.append(
                    SearchItemDto(
                        id=p_id,
                        type=SearchCategory.PERSON,
                        title=np.get("name", ""),
                        subtitle=np.get("current_role", "DART 등재 임원"),
                        badge="인물",
                        target_id=p_id,
                        source_url="https://dart.fss.or.kr"
                    )
                )

        return SearchUniversalResponseDto(
            status="success",
            query=q,
            total_count=len(results),
            results=results[:limit]
        )
