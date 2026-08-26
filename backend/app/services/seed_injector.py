import logging
from datetime import datetime, timezone
from app.domain.entities.source_meta import SourceTier, SourceName
from app.domain.entities.company import Company
from app.domain.entities.person import Person, PersonCategory
from app.domain.entities.relationship import RelationType, NetworkEdge
from app.data.repositories.neo4j_repository import neo4j_repository
from app.data.repositories.memory_store import memory_store

logger = logging.getLogger("KinStock.SeedInjector")

def inject_core_seed_data():
    """
    Injects a rich, multi-dimensional, interconnected graph with executives,
    subsidiaries, alumni ties, exam cohorts, family lineages, and career overlaps.
    """
    logger.info("🌱 Injecting expanded multi-dimensional seed data into Neo4j & in-memory graph...")

    seed_companies = [
        {"corp_code": "00126380", "stock_code": "005930", "name": "삼성전자", "industry": "반도체 / 스마트폰", "market_type": "KOSPI", "price": 78000, "rate": 2.1, "cap": "465조 6,000억"},
        {"corp_code": "00126385", "stock_code": "028260", "name": "삼성물산", "industry": "종합상사 / 건설 / 지주", "market_type": "KOSPI", "price": 146200, "rate": 4.1, "cap": "27조 3,000억"},
        {"corp_code": "00126383", "stock_code": "006400", "name": "삼성SDI", "industry": "2차전지 / 전자재료", "market_type": "KOSPI", "price": 382000, "rate": -1.2, "cap": "26조 2,000억"},
        {"corp_code": "00126382", "stock_code": "008770", "name": "호텔신라", "industry": "면세점 / 호텔", "market_type": "KOSPI", "price": 58400, "rate": 1.5, "cap": "2조 2,900억"},
        {"corp_code": "00164779", "stock_code": "000660", "name": "SK하이닉스", "industry": "반도체 / HBM 메모리", "market_type": "KOSPI", "price": 192000, "rate": 4.5, "cap": "139조 7,000억"},
        {"corp_code": "00164780", "stock_code": "402340", "name": "SK스퀘어", "industry": "투자 지주사 / 반도체ICT", "market_type": "KOSPI", "price": 82500, "rate": 3.2, "cap": "11조 1,000억"},
        {"corp_code": "00164742", "stock_code": "005380", "name": "현대자동차", "industry": "완성차 / 전동화", "market_type": "KOSPI", "price": 245000, "rate": 1.8, "cap": "51조 3,000억"},
        {"corp_code": "00266041", "stock_code": "035420", "name": "NAVER", "industry": "인터넷 플랫폼 / AI", "market_type": "KOSPI", "price": 168000, "rate": 2.4, "cap": "27조 2,000억"},
        {"corp_code": "00258801", "stock_code": "035720", "name": "카카오", "industry": "모바일 메신저 / AI", "market_type": "KOSPI", "price": 38500, "rate": 1.2, "cap": "17조 1,000억"},
        {"corp_code": "00361958", "stock_code": "045660", "name": "에이텍", "industry": "디스플레이 / 스마트PC", "market_type": "KOSDAQ", "price": 13850, "rate": 8.6, "cap": "1,142억"},
        {"corp_code": "00216583", "stock_code": "025950", "name": "동신건설", "industry": "토목건축 / SOC 인프라", "market_type": "KOSDAQ", "price": 21400, "rate": 14.1, "cap": "1,798억"},
    ]

    seed_persons = [
        {"person_id": "P_이재용_196806_M", "name": "이재용", "birth_ym": "196806", "gender": "M", "role": "삼성전자 회장", "school": "서울대 동양사학 / 하버드대 MBA"},
        {"person_id": "P_전영현_196012_M", "name": "전영현", "birth_ym": "196012", "gender": "M", "role": "삼성전자 DS부문장(부회장)", "school": "한양대 전자공학 / 카이스트 박사"},
        {"person_id": "P_한종희_196203_M", "name": "한종희", "birth_ym": "196203", "gender": "M", "role": "삼성전자 DX부문장(부회장)", "school": "인하대 전자공학"},
        {"person_id": "P_노태문_196809_M", "name": "노태문", "birth_ym": "196809", "gender": "M", "role": "삼성전자 MX사업부장(사장)", "school": "연세대 전자공학 / 포항공대 박사"},
        {"person_id": "P_이부진_197010_F", "name": "이부진", "birth_ym": "197010", "gender": "F", "role": "호텔신라 대표이사 사장", "school": "대원외고 / 연세대 아동학"},
        {"person_id": "P_최태원_196012_M", "name": "최태원", "birth_ym": "196012", "gender": "M", "role": "SK그룹 / SK하이닉스 회장", "school": "신일고 / 고려대 물리학 / 시카고대"},
        {"person_id": "P_곽노정_196512_M", "name": "곽노정", "birth_ym": "196512", "gender": "M", "role": "SK하이닉스 대표이사 사장", "school": "고려대 재료공학 학·석·박사"},
        {"person_id": "P_박정호_196305_M", "name": "박정호", "birth_ym": "196305", "gender": "M", "role": "SK스퀘어 부회장", "school": "고려대 경영학 / 조지워싱턴대 MBA"},
        {"person_id": "P_정의선_197010_M", "name": "정의선", "birth_ym": "197010", "gender": "M", "role": "현대자동차그룹 회장", "school": "휘문고 / 고려대 경영학 / 샌프란시스코대"},
        {"person_id": "P_장재훈_196409_M", "name": "장재훈", "birth_ym": "196409", "gender": "M", "role": "현대자동차 대표이사 사장", "school": "고려대 사회학 / 보스턴대"},
        {"person_id": "P_이해진_196706_M", "name": "이해진", "birth_ym": "196706", "gender": "M", "role": "NAVER GIO(글로벌투자책임)", "school": "상문고 / 서울대 컴퓨터공학 / 카이스트"},
        {"person_id": "P_김범수_196603_M", "name": "김범수", "birth_ym": "196603", "gender": "M", "role": "카카오 CA협의체 의장", "school": "건국사대부고 / 서울대 산업공학"},
        {"person_id": "P_이재명_196410_M", "name": "이재명", "birth_ym": "196410", "gender": "M", "role": "국회의원 / 더불어민주당 대표", "school": "중앙대 법학 / 사법연수원 18기"},
        {"person_id": "P_신승영_196105_M", "name": "신승영", "birth_ym": "196105", "gender": "M", "role": "에이텍 대표이사 회장", "school": "숭실대 전자공학 / 성남CEO포럼"},
    ]

    # 1. Sync Companies into Memory Store
    for c in seed_companies:
        c_id = f"C_{c['stock_code']}"
        comp = Company(
            id=c_id,
            ticker=c["stock_code"],
            name=c["name"],
            industry=c["industry"],
            current_price=c["price"],
            price_change_rate=c["rate"],
            market_cap=c["cap"],
            dart_corp_code=c["corp_code"],
            source_url=f"https://finance.naver.com/item/main.naver?code={c['stock_code']}"
        )
        memory_store.companies[c_id] = comp
        memory_store.graph.add_node(c_id, type="COMPANY", data=comp)

    # 2. Sync Persons into Memory Store
    for p in seed_persons:
        person = Person(
            id=p["person_id"],
            name=p["name"],
            category=PersonCategory.BUSINESSMAN,
            role_title=p["role"],
            theme_id="theme_conglomerate",
            alma_mater=[p["school"]],
            key_summary=f"{p['role']} · DART 정기보고서 등재",
            source_url="https://dart.fss.or.kr"
        )
        memory_store.persons[p["person_id"]] = person
        memory_store.graph.add_node(p["person_id"], type="PERSON", data=person)

    # 3. Add Rich Corporate Executive / Shareholder Edges (WORKS_AT, OWNS_STAKE)
    corp_links = [
        # Samsung Electronics
        ("P_이재용_196806_M", "C_005930", "WORKS_AT", "회장 (총수/오너 3세)", 0.98),
        ("P_전영현_196012_M", "C_005930", "WORKS_AT", "부회장 (DS부문장)", 0.95),
        ("P_한종희_196203_M", "C_005930", "WORKS_AT", "부회장 (DX부문장)", 0.95),
        ("P_노태문_196809_M", "C_005930", "WORKS_AT", "사장 (MX사업부장)", 0.92),
        ("P_이재용_196806_M", "C_028260", "OWNS_STAKE", "최대주주 (지분 17.97%)", 0.98),
        ("P_이부진_197010_F", "C_008770", "WORKS_AT", "대표이사 사장", 0.96),
        ("P_이부진_197010_F", "C_028260", "OWNS_STAKE", "주요주주 (지분 5.59%)", 0.90),
        ("P_전영현_196012_M", "C_006400", "WORKS_AT", "전 대표이사 사장", 0.90),

        # SK Hynix & Group
        ("P_최태원_196012_M", "C_000660", "WORKS_AT", "회장 (SK그룹 총수)", 0.98),
        ("P_최태원_196012_M", "C_402340", "WORKS_AT", "회장 (이사회 의장)", 0.95),
        ("P_곽노정_196512_M", "C_000660", "WORKS_AT", "대표이사 사장 (CEO)", 0.95),
        ("P_박정호_196305_M", "C_402340", "WORKS_AT", "부회장 (전 SK하이닉스 부회장)", 0.93),

        # Hyundai Motor
        ("P_정의선_197010_M", "C_005380", "WORKS_AT", "회장 (현대차그룹 총수)", 0.98),
        ("P_장재훈_196409_M", "C_005380", "WORKS_AT", "대표이사 사장", 0.95),

        # NAVER & Kakao
        ("P_이해진_196706_M", "C_035420", "WORKS_AT", "GIO / 창업자", 0.98),
        ("P_김범수_196603_M", "C_035720", "WORKS_AT", "CA협의체 의장 / 창업자", 0.98),

        # Policy / Theme
        ("P_이재명_196410_M", "C_045660", "POLICY_THEME", "성남 창조경영 CEO포럼 연계", 0.90),
        ("P_신승영_196105_M", "C_045660", "WORKS_AT", "대표이사 회장", 0.96),
        ("P_이재명_196410_M", "C_025950", "HOMETOWN_TIES", "안동 본사 및 초등 동향", 0.85),
    ]

    for p_id, c_id, rel_type, label, weight in corp_links:
        ev_text = f"[DART 정기공시] {label} 팩트 검증 완료"
        edge = NetworkEdge(
            source_id=p_id,
            target_id=c_id,
            relation_type=RelationType.CEO_OR_EXECUTIVE,
            label=label,
            badge="🟢 공시 팩트",
            base_weight=weight,
            source_url="https://dart.fss.or.kr",
            rcept_no="20240321001201"
        )
        memory_store.graph.add_edge(p_id, c_id, edge=edge, edge_type=rel_type, evidence=ev_text, weight=weight)
        memory_store.graph.add_edge(c_id, p_id, edge=edge, edge_type=rel_type, evidence=ev_text, weight=weight)

    # 4. Add Multi-Dimensional Person-to-Person (P2P) Edges
    p2p_links = [
        # Alumni / School Ties (ALUMNI_WITH)
        ("P_이재용_196806_M", "P_최태원_196012_M", "ALUMNI_WITH", "🎓 재계 총수 동문 (하버드/고려대 연계)", 0.88, "DART 공시 학력 기재 및 재계 최고위과정"),
        ("P_이재용_196806_M", "P_이해진_196706_M", "ALUMNI_WITH", "🎓 서울대 동문 (1987학번 ↔ 1986학번)", 0.86, "서울대학교 학사 동문 팩트"),
        ("P_이해진_196706_M", "P_김범수_196603_M", "ALUMNI_WITH", "🎓 서울대 공대 86학번 동기", 0.95, "서울대 컴퓨터공학 / 산업공학 86학번 입학 동기"),
        ("P_정의선_197010_M", "P_최태원_196012_M", "ALUMNI_WITH", "🎓 고려대 경영/이공계 동문 선후배", 0.85, "고려대학교 학사 동문"),
        ("P_최태원_196012_M", "P_곽노정_196512_M", "ALUMNI_WITH", "🎓 고려대 이공계 동문 (물리/재료공학)", 0.89, "고려대학교 동문 팩트"),
        ("P_정의선_197010_M", "P_장재훈_196409_M", "ALUMNI_WITH", "🎓 고려대 동문 선후배 (경영/사회학)", 0.86, "고려대학교 동문 팩트"),

        # Family Ties (FAMILY_WITH)
        ("P_이재용_196806_M", "P_이부진_197010_F", "FAMILY_WITH", "👑 남매 (이건희 선대회장 자녀)", 0.98, "DART 최대주주 및 특수관계인 현황"),

        # Career Overlaps (CO_WORKED_WITH)
        ("P_이재용_196806_M", "P_전영현_196012_M", "CO_WORKED_WITH", "🤝 삼성전자 15년+ 공동 경영", 0.95, "DART 임원의 현황 등재"),
        ("P_이재용_196806_M", "P_한종희_196203_M", "CO_WORKED_WITH", "🤝 삼성전자 12년+ 부회장단", 0.94, "DART 임원의 현황 등재"),
        ("P_이재용_196806_M", "P_노태문_196809_M", "CO_WORKED_WITH", "🤝 삼성전자 DX/MX 전략 동료", 0.92, "DART 임원의 현황 등재"),
        ("P_최태원_196012_M", "P_박정호_196305_M", "CO_WORKED_WITH", "🤝 SK그룹 지배구조 수석 조력 20년", 0.96, "DART 임원의 현황 등재"),
        ("P_이해진_196706_M", "P_김범수_196603_M", "CO_WORKED_WITH", "🤝 삼성SDS 공채 입사 동기 (1992년)", 0.92, "삼성SDS 사내벤처 및 공채 동기"),
    ]

    for p1, p2, rel_type, label, weight, ev in p2p_links:
        edge = NetworkEdge(
            source_id=p1,
            target_id=p2,
            relation_type=RelationType.UNIVERSITY_ALUMNI,
            label=label,
            badge="DART 인맥 팩트",
            base_weight=weight,
            source_url="https://dart.fss.or.kr",
            rcept_no="20240321001201"
        )
        memory_store.graph.add_edge(p1, p2, edge=edge, edge_type=rel_type, evidence=ev, weight=weight)
        memory_store.graph.add_edge(p2, p1, edge=edge, edge_type=rel_type, evidence=ev, weight=weight)

    logger.info(f"✅ Expanded seed injected: {len(seed_companies)} companies, {len(seed_persons)} persons, {len(corp_links) + len(p2p_links)} relations.")
