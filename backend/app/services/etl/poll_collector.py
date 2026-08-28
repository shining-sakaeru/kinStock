from typing import List, Dict, Any, Optional
from app.schemas.poll_event_schemas import (
    PollCandidateScore,
    PollSurveyDto,
    PollLeaderboardResponse
)

class PollCollectorService:
    """
    Collects, normalizes, and aggregates public opinion poll surveys.
    Provides latest leaderboard and historical multi-agency time-series approval trends.
    """

    def __init__(self):
        self._surveys: List[PollSurveyDto] = []
        self._init_seed_polls()

    def _init_seed_polls(self):
        # 1. Recent survey: 2026-08 4th week Gallup
        p1 = PollSurveyDto(
            poll_id="POLL_202608_GALLUP_W4",
            agency="한국갤럽",
            surveyed_at="2026-08-25",
            sample_size=1002,
            confidence_level=95.0,
            margin_of_error=3.1,
            survey_method="무선전화 RDD 표본 무작위 추출 (응답률 13.8%)",
            source_url="https://www.gallup.co.kr",
            candidates=[
                PollCandidateScore(
                    person_id="P_LEE_JM",
                    person_name="이재명",
                    party_or_group="더불어민주당",
                    role_title="국회의원 / 당대표",
                    approval_rate=38.5,
                    rank=1,
                    delta_rate=1.8,
                    badge_color="#0A84FF"
                ),
                PollCandidateScore(
                    person_id="P_HAN_DH",
                    person_name="한동훈",
                    party_or_group="국민의힘",
                    role_title="국회의원 / 당대표",
                    approval_rate=29.2,
                    rank=2,
                    delta_rate=-0.4,
                    badge_color="#EF4444"
                ),
                PollCandidateScore(
                    person_id="P_CHO_KUK",
                    person_name="조국",
                    party_or_group="조국혁신당",
                    role_title="국회의원 / 당대표",
                    approval_rate=10.4,
                    rank=3,
                    delta_rate=0.7,
                    badge_color="#30D158"
                ),
                PollCandidateScore(
                    person_id="P_OH_SH",
                    person_name="오세훈",
                    party_or_group="국민의힘",
                    role_title="서울특별시장",
                    approval_rate=7.8,
                    rank=4,
                    delta_rate=0.3,
                    badge_color="#BF5AF2"
                ),
                PollCandidateScore(
                    person_id="P_HONG_JP",
                    person_name="홍준표",
                    party_or_group="국민의힘",
                    role_title="대구광역시장",
                    approval_rate=5.5,
                    rank=5,
                    delta_rate=-0.2,
                    badge_color="#FF9F0A"
                ),
                PollCandidateScore(
                    person_id="P_LEE_JS",
                    person_name="이준석",
                    party_or_group="개혁신당",
                    role_title="국회의원",
                    approval_rate=4.2,
                    rank=6,
                    delta_rate=0.5,
                    badge_color="#FF6B00"
                ),
            ]
        )

        # 2. Previous survey: 2026-08 2nd week Realmeter
        p2 = PollSurveyDto(
            poll_id="POLL_202608_REALMETER_W2",
            agency="리얼미터",
            surveyed_at="2026-08-11",
            sample_size=1505,
            confidence_level=95.0,
            margin_of_error=2.5,
            survey_method="무선(97%)·유선(3%) 자동응답(ARS)",
            source_url="https://www.realmeter.net",
            candidates=[
                PollCandidateScore(
                    person_id="P_LEE_JM",
                    person_name="이재명",
                    party_or_group="더불어민주당",
                    role_title="국회의원 / 당대표",
                    approval_rate=36.7,
                    rank=1,
                    delta_rate=0.5,
                    badge_color="#0A84FF"
                ),
                PollCandidateScore(
                    person_id="P_HAN_DH",
                    person_name="한동훈",
                    party_or_group="국민의힘",
                    role_title="국회의원 / 당대표",
                    approval_rate=29.6,
                    rank=2,
                    delta_rate=1.2,
                    badge_color="#EF4444"
                ),
                PollCandidateScore(
                    person_id="P_CHO_KUK",
                    person_name="조국",
                    party_or_group="조국혁신당",
                    role_title="국회의원 / 당대표",
                    approval_rate=9.7,
                    rank=3,
                    delta_rate=-0.3,
                    badge_color="#30D158"
                ),
                PollCandidateScore(
                    person_id="P_OH_SH",
                    person_name="오세훈",
                    party_or_group="국민의힘",
                    role_title="서울특별시장",
                    approval_rate=7.5,
                    rank=4,
                    delta_rate=0.1,
                    badge_color="#BF5AF2"
                ),
                PollCandidateScore(
                    person_id="P_HONG_JP",
                    person_name="홍준표",
                    party_or_group="국민의힘",
                    role_title="대구광역시장",
                    approval_rate=5.7,
                    rank=5,
                    delta_rate=0.4,
                    badge_color="#FF9F0A"
                ),
                PollCandidateScore(
                    person_id="P_LEE_JS",
                    person_name="이준석",
                    party_or_group="개혁신당",
                    role_title="국회의원",
                    approval_rate=3.7,
                    rank=6,
                    delta_rate=-0.1,
                    badge_color="#FF6B00"
                ),
            ]
        )

        self._surveys = [p1, p2]

    def get_latest_leaderboard(self) -> PollLeaderboardResponse:
        latest = self._surveys[0]
        
        # Build time-series trends
        trends = [
            {"date": "2026-07-15", "이재명": 34.8, "한동훈": 27.5, "조국": 10.2, "오세훈": 7.0, "홍준표": 5.2, "이준석": 3.5},
            {"date": "2026-08-01", "이재명": 36.2, "한동훈": 28.4, "조국": 10.0, "오세훈": 7.4, "홍준표": 5.3, "이준석": 3.8},
            {"date": "2026-08-11", "이재명": 36.7, "한동훈": 29.6, "조국": 9.7, "오세훈": 7.5, "홍준표": 5.7, "이준석": 3.7},
            {"date": "2026-08-25", "이재명": 38.5, "한동훈": 29.2, "조국": 10.4, "오세훈": 7.8, "홍준표": 5.5, "이준석": 4.2},
        ]

        return PollLeaderboardResponse(
            status="success",
            latest_poll=latest,
            leaderboard=latest.candidates,
            historical_trends=trends
        )

    def get_candidate_approval(self, person_id: str) -> Optional[PollCandidateScore]:
        latest = self._surveys[0]
        for c in latest.candidates:
            if c.person_id == person_id or person_id in c.person_id or c.person_name in person_id:
                return c
        return None

poll_collector_service = PollCollectorService()
