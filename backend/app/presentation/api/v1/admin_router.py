import logging
from fastapi import APIRouter
from typing import Dict, Any
from app.services.batch.progress_manager import progress_manager, BatchPredictionMetrics
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
