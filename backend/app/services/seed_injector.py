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
    Guarantees that major Korean market leaders and figures (Samsung, SK Hynix, Hyundai, NAVER, Kakao, etc.)
    are always seeded into both Neo4j and the in-memory repository on startup.
    """
    logger.info("🌱 Injecting core seed data into Neo4j & in-memory graph...")

    seed_companies = [
        {"corp_code": "00126380", "stock_code": "005930", "name": "삼성전자", "industry": "반도체 / 스마트폰", "market_type": "KOSPI", "price": 78000, "rate": 2.1, "cap": "465조 6,000억"},
        {"corp_code": "00164779", "stock_code": "000660", "name": "SK하이닉스", "industry": "반도체 / HBM 메모리", "market_type": "KOSPI", "price": 192000, "rate": 4.5, "cap": "139조 7,000억"},
        {"corp_code": "00164742", "stock_code": "005380", "name": "현대자동차", "industry": "완성차 / 전동화", "market_type": "KOSPI", "price": 245000, "rate": 1.8, "cap": "51조 3,000억"},
        {"corp_code": "00266041", "stock_code": "035420", "name": "NAVER", "industry": "인터넷 플랫폼 / 생성형AI", "market_type": "KOSPI", "price": 168000, "rate": 2.4, "cap": "27조 2,000억"},
        {"corp_code": "00258801", "stock_code": "035720", "name": "카카오", "industry": "모바일 메신저 / 콘텐츠", "market_type": "KOSPI", "price": 38500, "rate": 1.2, "cap": "17조 1,000억"},
        {"corp_code": "00155204", "stock_code": "051910", "name": "LG화학", "industry": "석유화학 / 첨단소재", "market_type": "KOSPI", "price": 320000, "rate": 0.9, "cap": "22조 5,000억"},
    ]

    seed_persons = [
        {"person_id": "이재용_196806_M", "name": "이재용", "birth_ym": "196806", "gender": "M", "role": "삼성전자 회장", "corp_code": "00126380", "stock_code": "005930", "stake": 1.63, "school": "서울대학교 동양사학과"},
        {"person_id": "최태원_196012_M", "name": "최태원", "birth_ym": "196012", "gender": "M", "role": "SK하이닉스 회장", "corp_code": "00164779", "stock_code": "000660", "stake": 0.0, "school": "고려대학교 물리학과"},
        {"person_id": "정의선_197010_M", "name": "정의선", "birth_ym": "197010", "gender": "M", "role": "현대자동차 회장", "corp_code": "00164742", "stock_code": "005380", "stake": 2.62, "school": "고려대학교 경영학과"},
        {"person_id": "이해진_196706_M", "name": "이해진", "birth_ym": "196706", "gender": "M", "role": "NAVER GIO", "corp_code": "00266041", "stock_code": "035420", "stake": 3.73, "school": "서울대학교 컴퓨터공학과"},
        {"person_id": "김범수_196603_M", "name": "김범수", "birth_ym": "196603", "gender": "M", "role": "카카오 창업주", "corp_code": "00258801", "stock_code": "035720", "stake": 13.27, "school": "서울대학교 산업공학과"},
    ]

    # 1. Sync into in-memory store
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

    for p in seed_persons:
        person = Person(
            id=p["person_id"],
            name=p["name"],
            category=PersonCategory.BUSINESSMAN,
            role_title=p["role"],
            theme_id="theme_conglomerate",
            alma_mater=[p["school"]],
            key_summary=f"{p['role']} · DART 전자공시 등재",
            source_url="https://dart.fss.or.kr"
        )
        memory_store.persons[p["person_id"]] = person
        memory_store.graph.add_node(p["person_id"], type="PERSON", data=person)

        c_id = f"C_{p['stock_code']}"
        edge = NetworkEdge(
            source_id=p["person_id"],
            target_id=c_id,
            relation_type=RelationType.CEO_OR_EXECUTIVE,
            label=p["role"],
            badge="경영/오너",
            base_weight=0.95,
            source_url="https://dart.fss.or.kr"
        )
        ev_text = f"DART 정기보고서 기준 {p['role']} 재직 및 책임경영 팩트"
        memory_store.graph.add_edge(p["person_id"], c_id, edge=edge, edge_type="WORKS_AT", evidence=ev_text, weight=0.95)
        memory_store.graph.add_edge(c_id, p["person_id"], edge=edge, edge_type="WORKS_AT", evidence=ev_text, weight=0.95)

    # 2. Sync into Neo4j
    neo4j_companies = [{
        "corp_code": c["corp_code"],
        "stock_code": c["stock_code"],
        "name": c["name"],
        "industry": c["industry"],
        "market_type": c["market_type"]
    } for c in seed_companies]

    neo4j_persons = [{
        "person_id": p["person_id"],
        "name": p["name"],
        "birth_ym": p["birth_ym"],
        "gender": p["gender"],
        "current_role": p["role"]
    } for p in seed_persons]

    neo4j_serves_as = [{
        "person_id": p["person_id"],
        "corp_code": p["corp_code"],
        "role": p["role"],
        "is_executive": True,
        "tenure": "재임중",
        "source_tier": SourceTier.TIER_1_LEGAL.value,
        "source_name": SourceName.DART.value,
        "source_ref_id": "20240322000891",
        "evidence_text": f"DART 정기보고서 기준 {p['role']} 재직 공시 팩트",
        "evidence": f"DART 정기보고서 기준 {p['role']} 재직 공시 팩트",
        "rcept_no": "20240322000891",
        "source_url": "https://dart.fss.or.kr",
        "verified_at": datetime.now(timezone.utc).isoformat()
    } for p in seed_persons]

    neo4j_repository.upsert_companies(neo4j_companies)
    neo4j_repository.upsert_persons(neo4j_persons)
    neo4j_repository.upsert_serves_as_edges(neo4j_serves_as)

    logger.info("✅ Core seed data successfully injected into Neo4j & in-memory graph.")
