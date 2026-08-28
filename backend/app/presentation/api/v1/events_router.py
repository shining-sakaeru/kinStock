from fastapi import APIRouter, Path
from app.schemas.poll_event_schemas import PersonEventTimelineResponse
from app.services.etl.event_collector import event_collector_service

router = APIRouter()

@router.get("/timeline/{person_id}", response_model=PersonEventTimelineResponse, summary="후보별 주요 정치 이벤트 타임라인 조회")
def get_person_event_timeline(
    person_id: str = Path(..., description="조회할 인물 ID 또는 이름 (예: P_LEE_JM, 이재명, P_HAN_DH)")
):
    """
    Returns historical milestone events (declarations, primary wins, leadership conventions,
    legal outcomes, policy announcements) for the selected person.
    """
    return event_collector_service.get_events_for_person(person_id)
