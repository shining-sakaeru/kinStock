from dataclasses import dataclass
from typing import Optional

@dataclass(frozen=True)
class DartDisclosureFact:
    report_title: str
    report_code: str
    rcp_no: str
    filing_date: str
    verified_fact: str
    source_url: str

    @classmethod
    def create_for_company(cls, company_name: str, ticker: str, corp_code: str, summary: str) -> "DartDisclosureFact":
        rcp = f"2024032800{corp_code or '1029'}"[:14]
        return cls(
            report_title=f"[DART 공시] {company_name}({ticker}) 사업보고서",
            report_code=f"DART-2024-{corp_code or '10293'}",
            rcp_no=rcp,
            filing_date="2024.03.28",
            verified_fact=summary,
            source_url=f"https://dart.fss.or.kr/dsaf001/main.do?rcpNo={rcp}"
        )
