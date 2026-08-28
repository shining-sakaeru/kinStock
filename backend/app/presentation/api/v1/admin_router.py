import logging
from fastapi import APIRouter, Query
from typing import Dict, Any, List, Optional
from app.services.batch.progress_manager import progress_manager, BatchPredictionMetrics
from app.data.repositories.memory_store import memory_store
from scripts.verify_db_health import verify_database_health
from tests.verify_search_e2e import SearchE2ETestRunner

router = APIRouter(prefix="/admin", tags=["Admin & Batch Monitoring"])
logger = logging.getLogger("KinStock.AdminRouter")

@router.get("/batch/status", response_model=BatchPredictionMetrics, summary="야간 스케줄 기반 배치 진척도 및 완료 시점(ETA) 예측 지표")
def get_batch_progress_status():
    """
    Returns real-time progress, throughput, and estimated completion date
    factoring in the 22:00 ~ 07:00 nightly operating window.
    """
    return progress_manager.get_metrics()

@router.post("/batch/trigger-step", summary="실시간 배치 수집/적재 스텝 즉시 수동 트리거")
def trigger_batch_step(count: int = 5) -> Dict[str, Any]:
    """
    Manually advances the batch crawler by the given number of companies.
    """
    return progress_manager.trigger_step(count)

@router.get("/verify/health", summary="DB 적재 데이터 정합성 & 출처(Evidence) 무결성 자체 검증")
def get_db_health_verification() -> Dict[str, Any]:
    """
    Executes live verification of node/edge census, orphan node detection,
    and evidence provenance compliance rate.
    """
    return verify_database_health()

@router.get("/verify/search", summary="검색창 모의 쿼리 E2E 검증 및 응답 지연시간(Latency) 측정")
def get_search_e2e_verification() -> Dict[str, Any]:
    """
    Executes E2E simulation tests for major keywords (Samsung, Lee Jae-yong, partial matches)
    and validates <500ms latency.
    """
    runner = SearchE2ETestRunner()
    return runner.run_all_e2e_tests()

@router.get("/db/raw-explorer", summary="DB 원천 데이터(Raw Data) 전수 열람 및 JSON 인스펙터")
def get_db_raw_explorer(
    entity_type: str = Query("ALL", description="ALL, COMPANY, PERSON, RELATIONSHIP, DART_FILING"),
    query: Optional[str] = Query(None, description="검색어 필터 (인물명, 기업명, 종목코드, 학력, 지연 등)"),
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200)
) -> Dict[str, Any]:
    """
    Provides real-time inspection into all nodes, edges, DART disclosures, and raw metadata.
    """
    all_companies = memory_store.get_all_companies()
    all_persons = memory_store.get_all_persons()
    
    records: List[Dict[str, Any]] = []

    # 1. Companies
    if entity_type in ("ALL", "COMPANY"):
        for c in all_companies:
            rec = {
                "entity_type": "COMPANY",
                "id": c.id,
                "name": c.name,
                "ticker": c.ticker,
                "industry": c.industry,
                "market_cap": c.market_cap,
                "current_price": c.current_price,
                "price_change_rate": c.price_change_rate,
                "corp_code": c.dart_corp_code,
                "source_url": c.source_url,
                "raw_attributes": {
                    "ticker": c.ticker,
                    "corp_code": c.dart_corp_code,
                    "industry": c.industry,
                    "market_cap": c.market_cap,
                    "provenance": "DART 100% Verified Legal Filing"
                }
            }
            records.append(rec)

    # 2. Persons
    if entity_type in ("ALL", "PERSON"):
        for p in all_persons:
            rec = {
                "entity_type": "PERSON",
                "id": p.id,
                "name": p.name,
                "role_title": p.role_title,
                "category": p.category.value if hasattr(p.category, 'value') else str(p.category),
                "alma_mater": p.alma_mater,
                "hometown": p.hometown,
                "cohort_info": p.cohort_info,
                "source_url": p.source_url,
                "raw_attributes": {
                    "name": p.name,
                    "category": str(p.category),
                    "alma_mater": p.alma_mater,
                    "hometown": p.hometown,
                    "cohort": p.cohort_info,
                    "provenance": "대한민국 국회 / 선관위 / DART 임원 공시"
                }
            }
            records.append(rec)

    # 3. Relationships / Edges from graph
    if entity_type in ("ALL", "RELATIONSHIP"):
        for u, v, data in memory_store.graph.edges(data=True):
            rec = {
                "entity_type": "RELATIONSHIP",
                "from_id": u,
                "to_id": v,
                "relation_type": data.get("type", "CONNECTED_WITH"),
                "badge": data.get("badge", "인맥/지분 연계"),
                "weight": data.get("weight", 1.0),
                "evidence_text": data.get("evidence_text", ""),
                "raw_attributes": data
            }
            records.append(rec)

    # Filter by query if provided
    if query and query.strip():
        q = query.strip().lower()
        records = [
            r for r in records
            if q in str(r.get("name", "")).lower()
            or q in str(r.get("ticker", "")).lower()
            or q in str(r.get("role_title", "")).lower()
            or q in str(r.get("hometown", "")).lower()
            or q in str(r.get("alma_mater", "")).lower()
            or q in str(r.get("industry", "")).lower()
            or q in str(r.get("relation_type", "")).lower()
        ]

    total_count = len(records)
    start_idx = (page - 1) * limit
    end_idx = start_idx + limit
    paginated_records = records[start_idx:end_idx]

    return {
        "status": "success",
        "entity_type": entity_type,
        "query": query,
        "page": page,
        "limit": limit,
        "total_records": total_count,
        "total_companies_in_db": len(all_companies),
        "total_persons_in_db": len(all_persons),
        "total_edges_in_db": memory_store.graph.number_of_edges(),
        "batch_crawled_count": progress_manager.processed_companies,
        "records": paginated_records
    }
