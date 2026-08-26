from typing import List, Optional
from app.domain.entities.person import Person
from app.domain.entities.company import Company
from app.domain.entities.theme import Theme
from app.domain.entities.dart_fact import DartDisclosureFact
from app.data.dtos.person_dtos import PersonDto
from app.data.dtos.stock_dtos import CompanyDto
from app.data.dtos.theme_dtos import ThemeDto
from app.data.dtos.common_dtos import DartFactDto

class DomainDtoMapper:
    @staticmethod
    def to_person_dto(person: Person) -> PersonDto:
        return PersonDto(
            id=person.id,
            name=person.name,
            category=person.category.value,
            role_title=person.role_title,
            theme_id=person.theme_id,
            hometown=person.hometown,
            alma_mater=person.alma_mater,
            cohort_info=person.cohort_info,
            key_summary=person.key_summary,
            source_url=person.source_url
        )

    @staticmethod
    def to_company_dto(company: Company) -> CompanyDto:
        return CompanyDto(
            id=company.id,
            ticker=company.ticker,
            name=company.name,
            industry=company.industry,
            current_price=company.current_price,
            price_change_rate=company.price_change_rate,
            market_cap=company.market_cap,
            dart_corp_code=company.dart_corp_code,
            source_url=company.source_url
        )

    @staticmethod
    def to_theme_dto(theme: Theme) -> ThemeDto:
        return ThemeDto(
            id=theme.id,
            code=theme.code.value,
            title=theme.title,
            short_title=theme.short_title,
            description=theme.description,
            icon_name=theme.icon_name,
            badge_color=theme.badge_color,
            figure_count=theme.figure_count
        )

    @staticmethod
    def to_dart_fact_dto(dart_fact: Optional[DartDisclosureFact]) -> Optional[DartFactDto]:
        if not dart_fact:
            return None
        return DartFactDto(
            report_title=dart_fact.report_title,
            report_code=dart_fact.report_code,
            rcp_no=dart_fact.rcp_no,
            filing_date=dart_fact.filing_date,
            verified_fact=dart_fact.verified_fact,
            source_url=dart_fact.source_url
        )
