from typing import List
from app.domain.repositories.person_repository import PersonRepository
from app.domain.repositories.company_repository import CompanyRepository
from app.domain.repositories.theme_repository import ThemeRepository
from app.data.dtos.search_dtos import SearchItemDto, SearchCategory, SearchUniversalResponseDto

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

        # 1. Search Themes
        themes = self.theme_repo.search_themes(q, limit=3)
        for t in themes:
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

        # 2. Search Persons
        persons = self.person_repo.search_persons(q, limit=5)
        for p in persons:
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

        # 3. Search Companies
        companies = self.company_repo.search_companies(q, limit=5)
        for c in companies:
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

        return SearchUniversalResponseDto(
            status="success",
            query=q,
            total_count=len(results),
            results=results[:limit]
        )
