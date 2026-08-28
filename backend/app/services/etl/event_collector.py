from typing import List, Dict, Any, Optional
from app.schemas.poll_event_schemas import (
    EventType,
    EventEvidenceTier,
    PoliticalEventDto,
    PersonEventTimelineResponse
)
from app.data.repositories.memory_store import memory_store

class EventCollectorService:
    """
    Collects, indexes, and normalizes key political milestones (declarations, primary wins,
    leadership conventions, legal outcomes, policy launches).
    """

    def __init__(self):
        self._events: List[PoliticalEventDto] = []
        self._init_seed_events()

    def _init_seed_events(self):
        events_data = [
            # 1. 이재명 Events
            PoliticalEventDto(
                event_id="EVT_LEE_JM_2026_LEADERSHIP",
                person_id="P_LEE_JM",
                person_name="이재명",
                title="더불어민주당 전당대회 연임 당선 (득표율 85.4%)",
                event_type=EventType.PARTY_LEADERSHIP,
                event_type_label="당대표 당선",
                occurred_at="2026-08-18",
                significance_score=4.9,
                evidence_tier=EventEvidenceTier.TIER_1_LEGAL,
                evidence_tier_badge="🟢 공시/선관위 팩트",
                summary="더불어민주당 전국당원대회에서 역대 최고 득표율로 연임에 성공하여 대권 가도 주도권 확립.",
                source_agency="중앙선거관리위원회 / 더불어민주당 선관위",
                source_url="https://theminjoo.kr"
            ),
            PoliticalEventDto(
                event_id="EVT_LEE_JM_2026_POLICY",
                person_id="P_LEE_JM",
                person_name="이재명",
                title="기본소득 및 스마트 행정 PC 인프라 전국 확대 공약 발표",
                event_type=EventType.POLICY_LAUNCH,
                event_type_label="핵심 정책 발표",
                occurred_at="2026-06-12",
                significance_score=4.2,
                evidence_tier=EventEvidenceTier.TIER_2_OFFICIAL,
                evidence_tier_badge="🔵 공식 정당 발표",
                summary="공공 클라우드 및 공공기관 스마트PC 도입 의무화 정책 비전 선포.",
                source_agency="더불어민주당 정책위원회",
                source_url="https://theminjoo.kr/policy"
            ),
            PoliticalEventDto(
                event_id="EVT_LEE_JM_2025_LEGAL",
                person_id="P_LEE_JM",
                person_name="이재명",
                title="공직선거법 관련 1심 재판 주요 쟁점 무죄 판결",
                event_type=EventType.LEGAL_OUTCOME,
                event_type_label="사법 판결",
                occurred_at="2025-11-20",
                significance_score=4.8,
                evidence_tier=EventEvidenceTier.TIER_1_LEGAL,
                evidence_tier_badge="🟢 법원 공식 판결",
                summary="사법 리스크 해소 국면 진입으로 관련 테마주 일제히 급등 반응.",
                source_agency="서울중앙지방법원",
                source_url="https://www.scourt.go.kr"
            ),

            # 2. 한동훈 Events
            PoliticalEventDto(
                event_id="EVT_HAN_DH_2026_LEADERSHIP",
                person_id="P_HAN_DH",
                person_name="한동훈",
                title="국민의힘 전당대회 대표 당선 (과반 득표)",
                event_type=EventType.PARTY_LEADERSHIP,
                event_type_label="당대표 당선",
                occurred_at="2026-07-23",
                significance_score=4.9,
                evidence_tier=EventEvidenceTier.TIER_1_LEGAL,
                evidence_tier_badge="🟢 선관위 공식 팩트",
                summary="국민의힘 제4차 전당대회에서 당대표로 선출되며 여권 차기 대선 주자 1위 공고화.",
                source_agency="국민의힘 선거관리위원회",
                source_url="https://www.peoplepowerparty.kr"
            ),
            PoliticalEventDto(
                event_id="EVT_HAN_DH_2026_POLICY",
                person_id="P_HAN_DH",
                person_name="한동훈",
                title="격차해소 및 청년 창업·반도체 특구 입법 추진",
                event_type=EventType.POLICY_LAUNCH,
                event_type_label="정책 비전 선포",
                occurred_at="2026-08-05",
                significance_score=4.0,
                evidence_tier=EventEvidenceTier.TIER_2_OFFICIAL,
                evidence_tier_badge="🔵 당 공식 발표",
                summary="미래 첨단산업 육성 및 격차 해소 특별법 발의.",
                source_agency="국민의힘 정책국",
                source_url="https://www.peoplepowerparty.kr"
            ),

            # 3. 조국 Events
            PoliticalEventDto(
                event_id="EVT_CHO_KUK_2026_PARTY",
                person_id="P_CHO_KUK",
                person_name="조국",
                title="조국혁신당 2기 지도부 출범 및 전국 정당화 선언",
                event_type=EventType.PARTY_LEADERSHIP,
                event_type_label="당대표 선출",
                occurred_at="2026-07-20",
                significance_score=4.3,
                evidence_tier=EventEvidenceTier.TIER_2_OFFICIAL,
                evidence_tier_badge="🔵 당 공식 발표",
                summary="원내 3당으로서 정치 개혁 및 사법 개혁 드라이브 천명.",
                source_agency="조국혁신당",
                source_url="https://rebuildingkorea.kr"
            ),

            # 4. 오세훈 Events
            PoliticalEventDto(
                event_id="EVT_OH_SH_2026_POLICY",
                person_id="P_OH_SH",
                person_name="오세훈",
                title="서울 대개조 및 한강 르네상스 2.0 마스터플랜 발표",
                event_type=EventType.POLICY_LAUNCH,
                event_type_label="시정 마스터플랜",
                occurred_at="2026-06-30",
                significance_score=4.1,
                evidence_tier=EventEvidenceTier.TIER_1_LEGAL,
                evidence_tier_badge="🟢 서울시 공식 고시",
                summary="도심 대규모 SOC 인프라 재구조화 발표로 토목·건설주 수혜 기대감 고조.",
                source_agency="서울특별시청",
                source_url="https://www.seoul.go.kr"
            ),
        ]
        self._events = events_data

    def get_events_for_person(self, person_id: str) -> PersonEventTimelineResponse:
        matched: List[PoliticalEventDto] = []
        person = memory_store.get_person_by_id(person_id)
        p_name = person.name if person else person_id

        for ev in self._events:
            if ev.person_id == person_id or person_id in ev.person_id or ev.person_name in person_id:
                matched.append(ev)

        # Sort by occurred_at descending (most recent first)
        matched.sort(key=lambda x: x.occurred_at, reverse=True)

        return PersonEventTimelineResponse(
            status="success",
            person_id=person_id,
            person_name=p_name,
            total_events=len(matched),
            events=matched
        )

    def get_event_by_id(self, event_id: str) -> Optional[PoliticalEventDto]:
        for ev in self._events:
            if ev.event_id == event_id:
                return ev
        return None

event_collector_service = EventCollectorService()
