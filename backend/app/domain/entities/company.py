from dataclasses import dataclass
from typing import Optional

@dataclass(frozen=True)
class Company:
    id: str
    ticker: str
    name: str
    industry: str
    current_price: float
    price_change_rate: float
    market_cap: str
    dart_corp_code: Optional[str] = None
    source_url: str = "https://dart.fss.or.kr"
