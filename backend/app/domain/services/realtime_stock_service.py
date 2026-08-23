import time
import httpx
from typing import Dict, Optional, Tuple
from app.domain.entities.company import Company

class RealtimeStockService:
    """
    Hybrid Real-time Stock Quote Service:
    - Layer 2: On-demand live quote fetching from Naver Finance API with TTL caching (30s).
    - Returns (current_price, price_change_rate, market_cap)
    """
    def __init__(self, cache_ttl_seconds: int = 30):
        self.cache_ttl = cache_ttl_seconds
        self._cache: Dict[str, Tuple[float, float, str, float]] = {} # ticker -> (price, change, cap, timestamp)

    def fetch_quote(self, ticker: str, fallback_company: Optional[Company] = None) -> Tuple[int, float, str]:
        now = time.time()
        # Check cache
        if ticker in self._cache:
            price, change, cap, ts = self._cache[ticker]
            if now - ts < self.cache_ttl:
                return int(price), change, cap

        # Live fetch from Naver Finance mobile API
        url = f"https://m.stock.naver.com/api/stock/{ticker}/basic"
        try:
            with httpx.Client(timeout=2.0) as client:
                res = client.get(url, headers={"User-Agent": "Mozilla/5.0"})
                if res.status_code == 200:
                    data = res.json()
                    now_val = data.get("nowVal", "")
                    change_rate = data.get("changeRate", "0.0")
                    m_cap = data.get("marketValue", "")

                    if now_val:
                        price = int(str(now_val).replace(",", ""))
                        rate = float(str(change_rate).replace("%", "").replace(",", ""))
                        cap_str = f"{m_cap}억" if m_cap else (fallback_company.market_cap if fallback_company else "1,000억")
                        self._cache[ticker] = (price, rate, cap_str, now)
                        return price, rate, cap_str
        except Exception:
            pass

        # Fallback to stored values
        if fallback_company:
            return fallback_company.current_price, fallback_company.price_change_rate, fallback_company.market_cap
        return 20000, 0.0, "1,000억"

# Singleton instance
realtime_stock_service = RealtimeStockService()
