from fastapi import APIRouter
from app.schemas.poll_event_schemas import PollLeaderboardResponse
from app.services.etl.poll_collector import poll_collector_service

router = APIRouter()

@router.get("/leaderboard", response_model=PollLeaderboardResponse, summary="여론조사 지지율 랭킹 및 시계열 추이 조회")
def get_poll_leaderboard():
    """
    Returns latest aggregated public poll surveys with candidate approval rates,
    rankings, delta changes, and historical time-series trends.
    """
    return poll_collector_service.get_latest_leaderboard()
