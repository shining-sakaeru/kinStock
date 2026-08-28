from fastapi import APIRouter, Path
from app.schemas.poll_event_schemas import EventStockImpactResponse
from app.services.scoring.event_study import event_study_analyzer

router = APIRouter()

@router.get("/stock-impact/{event_id}", response_model=EventStockImpactResponse, summary="사건별 연관기업 주가 반응 및 이상수익률(CAR) 분석")
def get_event_stock_impact(
    event_id: str = Path(..., description="이벤트 ID (예: EVT_LEE_JM_2026_LEADERSHIP, EVT_HAN_DH_2026_LEADERSHIP)")
):
    """
    Computes and returns Cumulative Abnormal Return (CAR[-3, +5]), D0 Day-of-Event return,
    and Volume Spike Multipliers for all connected theme stocks of the event.
    """
    return event_study_analyzer.calculate_car_matrix(event_id)
