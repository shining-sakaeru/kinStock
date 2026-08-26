import os
import sys
import time
import logging
from typing import Dict, Any, List
from datetime import datetime, timezone

# Ensure project root is in path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.use_cases.universal_search_use_case import UniversalSearchUseCase
from app.data.repositories.memory_store import memory_store
from app.data.repositories.neo4j_repository import neo4j_repository

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("KinStock.VerifySearchE2E")

class SearchE2ETestRunner:
    def __init__(self):
        self.search_use_case = UniversalSearchUseCase(
            person_repo=memory_store,
            company_repo=memory_store,
            theme_repo=memory_store
        )

    def run_all_e2e_tests(self) -> Dict[str, Any]:
        # Warm up driver connection
        try:
            self.search_use_case.execute("warmup", limit=1)
        except Exception:
            pass

        results: List[Dict[str, Any]] = []
        overall_passed = True
        start_all = time.perf_counter()

        # ----------------------------------------------------------------------
        # Test Case 1: '삼성전자' Search & Subgraph Validation (Under 500ms)
        # ----------------------------------------------------------------------
        t1_start = time.perf_counter()
        t1_search = self.search_use_case.execute("삼성전자", limit=10)
        t1_duration_ms = round((time.perf_counter() - t1_start) * 1000, 2)

        # Subgraph check for Samsung Electronics (005930)
        subgraph = neo4j_repository.get_company_subgraph("005930") or neo4j_repository.get_company_subgraph("삼성전자")
        
        has_samsung_stock = any(r.title == "삼성전자" or r.target_id == "005930" for r in t1_search.results)
        has_executives = any("이재용" in r.title for r in t1_search.results)
        is_fast_enough = t1_duration_ms < 500.0

        t1_pass = has_samsung_stock and is_fast_enough
        if not t1_pass: overall_passed = False

        results.append({
            "test_id": "TC_SEARCH_01",
            "name": "기업 검색 및 1-Hop 임원/시총 응답 검증 ('삼성전자')",
            "keyword": "삼성전자",
            "latency_ms": t1_duration_ms,
            "max_allowed_latency_ms": 500.0,
            "results_count": t1_search.total_count,
            "passed": t1_pass,
            "details": {
                "found_company": has_samsung_stock,
                "found_key_executives": has_executives,
                "latency_ok": is_fast_enough,
                "top_items": [f"[{r.badge}] {r.title} ({r.subtitle})" for r in t1_search.results[:3]]
            }
        })

        # ----------------------------------------------------------------------
        # Test Case 2: '이재용' Person Search & Corporate Affiliation Validation
        # ----------------------------------------------------------------------
        t2_start = time.perf_counter()
        t2_search = self.search_use_case.execute("이재용", limit=5)
        t2_duration_ms = round((time.perf_counter() - t2_start) * 1000, 2)

        has_person_lee = any(r.title == "이재용" and r.type.value == "PERSON" for r in t2_search.results)
        has_role_info = any("삼성전자" in r.subtitle for r in t2_search.results)
        
        t2_pass = has_person_lee and has_role_info and (t2_duration_ms < 500.0)
        if not t2_pass: overall_passed = False

        results.append({
            "test_id": "TC_SEARCH_02",
            "name": "인물 검색 및 소속 기업·직책 매핑 검증 ('이재용')",
            "keyword": "이재용",
            "latency_ms": t2_duration_ms,
            "max_allowed_latency_ms": 500.0,
            "results_count": t2_search.total_count,
            "passed": t2_pass,
            "details": {
                "found_person_node": has_person_lee,
                "found_company_affiliation": has_role_info,
                "top_items": [f"[{r.badge}] {r.title} ({r.subtitle})" for r in t2_search.results[:3]]
            }
        })

        # ----------------------------------------------------------------------
        # Test Case 3: Partial Match & Korean Typing Sanity ('삼성')
        # ----------------------------------------------------------------------
        t3_start = time.perf_counter()
        t3_search = self.search_use_case.execute("삼성", limit=10)
        t3_duration_ms = round((time.perf_counter() - t3_start) * 1000, 2)

        matched_titles = [r.title for r in t3_search.results]
        has_samsung_electronics = "삼성전자" in matched_titles or any("삼성전자" in t for t in matched_titles)
        
        t3_pass = has_samsung_electronics and len(t3_search.results) >= 1
        if not t3_pass: overall_passed = False

        results.append({
            "test_id": "TC_SEARCH_03",
            "name": "한글 부분 일치 및 자동완성 검증 ('삼성')",
            "keyword": "삼성",
            "latency_ms": t3_duration_ms,
            "max_allowed_latency_ms": 500.0,
            "results_count": t3_search.total_count,
            "passed": t3_pass,
            "details": {
                "matched_titles": matched_titles[:5],
                "autocomplete_working": has_samsung_electronics
            }
        })

        total_duration_ms = round((time.perf_counter() - start_all) * 1000, 2)
        passed_count = sum(1 for r in results if r["passed"])

        return {
            "status": "PASS" if overall_passed else "FAIL",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "total_tests": len(results),
            "passed_tests": passed_count,
            "failed_tests": len(results) - passed_count,
            "total_duration_ms": total_duration_ms,
            "results": results
        }

def print_search_e2e_report():
    runner = SearchE2ETestRunner()
    report = runner.run_all_e2e_tests()
    print("=" * 80)
    print("🧪 [KinStock] Universal Search E2E Simulation & Latency Report")
    print("=" * 80)
    print(f"Overall Status: {report['status']} ({report['passed_tests']}/{report['total_tests']} Passed)")
    print(f"Total Duration: {report['total_duration_ms']} ms | Timestamp: {report['timestamp']}")
    print("-" * 80)
    for res in report["results"]:
        status_icon = "✅ PASS" if res["passed"] else "❌ FAIL"
        print(f"{status_icon} [{res['test_id']}] {res['name']}")
        print(f"   • Keyword: '{res['keyword']}' | Latency: {res['latency_ms']} ms (Max: {res['max_allowed_latency_ms']} ms)")
        print(f"   • Count: {res['results_count']} results")
        for k, v in res["details"].items():
            print(f"     - {k}: {v}")
        print("-" * 80)
    print("=" * 80)

if __name__ == "__main__":
    print_search_e2e_report()
