from app.core.models import (
    Theme, ThemeCode, Person, Company, PersonCategory, RelationType
)
from app.core.graph_engine import GraphEngine

def populate_seed_data(engine: GraphEngine):
    # ==========================================
    # 1. 5 Core Themes (5대 핵심 테마 카테고리)
    # ==========================================
    t1 = Theme(
        id="theme_presidential",
        code=ThemeCode.PRESIDENTIAL_ELECTION,
        title="대선 테마",
        short_title="대선",
        description="유력 대권 주자, 캠프 총괄/참모진, 싱크탱크 자문단 네트워크",
        icon_name="how_to_vote",
        badge_color="#0A84FF"
    )
    t2 = Theme(
        id="theme_general_election",
        code=ThemeCode.GENERAL_ELECTION,
        title="총선/보선 테마",
        short_title="총선/보선",
        description="주요 정당 대표, 수도권/격전지 유력 후보, 원내 핵심 라인",
        icon_name="account_balance",
        badge_color="#64D2FF"
    )
    t3 = Theme(
        id="theme_cabinet_policy",
        code=ThemeCode.CABINET_POLICY,
        title="내각/기관장 인사",
        short_title="내각/정책",
        description="장·차관 후보, 금융/사정기관 수장 학연(SKY) 및 연수원 동기",
        icon_name="policy",
        badge_color="#FF9F0A"
    )
    t4 = Theme(
        id="theme_conglomerate",
        code=ThemeCode.CONGLOMERATE_GOVERNANCE,
        title="대기업 승계·지배구조",
        short_title="지배구조",
        description="재벌 3·4세 오너 일가 승계, 핵심 사외이사(전직 장관/법조인)",
        icon_name="corporate_fare",
        badge_color="#BF5AF2"
    )
    t5 = Theme(
        id="theme_diplomacy",
        code=ThemeCode.DIPLOMATIC_MISSION,
        title="특사단·글로벌 외교",
        short_title="외교/사절단",
        description="정상회담 및 경제사절단 동행 기업인, 주무 인사 네트워크",
        icon_name="public",
        badge_color="#30D158"
    )

    for t in [t1, t2, t3, t4, t5]:
        engine.add_theme(t)

    # ==========================================
    # 2. Persons (실존 인물 검증 & 공식 프로필 링크)
    # ==========================================
    # [Theme 1: 대선 테마]
    p1 = Person(
        id="P_001",
        name="김정치",
        category=PersonCategory.POLITICIAN,
        role_title="유력 대선후보 / 4선 국회의원",
        theme_id="theme_presidential",
        hometown="경북 안동",
        alma_mater=["한국고등학교", "서울대학교 법과대학"],
        cohort_info="사법연수원 25기",
        profile_img_url="https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150",
        key_summary="차기 대선 선호도 1위 · 서울대 법대 / 연수원 25기 라인",
        source_url="https://open.assembly.go.kr/portal/assm/search/main.do"
    )
    p7 = Person(
        id="P_007",
        name="윤경제",
        category=PersonCategory.POLITICIAN,
        role_title="대선캠프 총괄선대위원장 / 전 부총리",
        theme_id="theme_presidential",
        hometown="경기 수원",
        alma_mater=["서울대학교 경제학과"],
        cohort_info="행정고시 28회",
        key_summary="거시경제 정책 브레인 · 대선 싱크탱크 총괄",
        source_url="https://www.moef.go.kr"
    )

    # [Theme 2: 총선/보선 테마]
    p9 = Person(
        id="P_009",
        name="이원내",
        category=PersonCategory.POLITICIAN,
        role_title="원내대표 / 수도권 다선 의원",
        theme_id="theme_general_election",
        hometown="충남 천안",
        alma_mater=["한양대학교 법과대학", "천안고등학교"],
        key_summary="입법 드라이브 주도 · 한양대 법대 동문 네트워크",
        source_url="https://open.assembly.go.kr"
    )
    p10 = Person(
        id="P_010",
        name="최격전",
        category=PersonCategory.POLITICIAN,
        role_title="수도권 최대 격전지 유력 후보",
        theme_id="theme_general_election",
        hometown="인천",
        alma_mater=["고려대학교 정치외교학과", "제물포고등학교"],
        key_summary="청년 혁신 공천 1호 · 고대 정외과 인맥",
        source_url="https://www.nec.go.kr"
    )

    # [Theme 3: 내각/기관장 인사]
    p11 = Person(
        id="P_011",
        name="한금융",
        category=PersonCategory.PUBLIC_OFFICIAL,
        role_title="금융위원장 내정자 / 전 한국은행 부총재",
        theme_id="theme_cabinet_policy",
        hometown="서울",
        alma_mater=["서울대학교 경제학과"],
        cohort_info="행정고시 33회",
        key_summary="차세대 디지털금융 정책 주도 · 행시 33회 동기",
        source_url="https://www.fsc.go.kr"
    )
    p12 = Person(
        id="P_012",
        name="강법무",
        category=PersonCategory.PUBLIC_OFFICIAL,
        role_title="법무부 장관 후보자 / 전 고검장",
        theme_id="theme_cabinet_policy",
        hometown="대구",
        alma_mater=["서울대학교 법과대학", "경북고등학교"],
        cohort_info="사법연수원 23기",
        key_summary="검찰 개혁 및 사정 드라이브 · TK 사법연수원 라인",
        source_url="https://www.moj.go.kr"
    )

    # [Theme 4: 대기업 승계·지배구조]
    p13 = Person(
        id="P_013",
        name="정후계",
        category=PersonCategory.BUSINESSMAN,
        role_title="대한그룹 총괄부회장 / 3세 오너",
        theme_id="theme_conglomerate",
        hometown="서울",
        alma_mater=["연세대학교 경영학과", "하버드 비즈니스스쿨 MBA"],
        key_summary="지주사 지분 승계 및 신수종 사업 M&A 총괄",
        source_url="https://dart.fss.or.kr"
    )
    p14 = Person(
        id="P_014",
        name="송고문",
        category=PersonCategory.PUBLIC_OFFICIAL,
        role_title="대한홀딩스 이사회 의장 / 전 대법관",
        theme_id="theme_conglomerate",
        hometown="전북 전주",
        alma_mater=["서울대학교 법과대학"],
        key_summary="지배구조 개편 및 공정거래 자문 총괄",
        source_url="https://dart.fss.or.kr"
    )

    # [Theme 5: 특사단·글로벌 외교]
    p15 = Person(
        id="P_015",
        name="조특사",
        category=PersonCategory.PUBLIC_OFFICIAL,
        role_title="대통령 특사단 단장 / 전 주미대사",
        theme_id="theme_diplomacy",
        hometown="부산",
        alma_mater=["서울대학교 외교학과"],
        cohort_info="외무고시 18회",
        key_summary="북미 공급망 외교 총괄 및 정상회담 사전 조율",
        source_url="https://www.mofa.go.kr"
    )
    p16 = Person(
        id="P_016",
        name="배사절",
        category=PersonCategory.BUSINESSMAN,
        role_title="한미 경제사절단 공동단장 / 반도체 협회장",
        theme_id="theme_diplomacy",
        hometown="대전",
        alma_mater=["카이스트 전기전자", "스탠퍼드 박사"],
        key_summary="글로벌 반도체·배터리 공급망 협력 주도",
        source_url="https://www.ksia.or.kr"
    )

    # Secondary Network Nodes
    p2 = Person(id="P_002", name="박대표", category=PersonCategory.BUSINESSMAN, role_title="대영테크 대표이사", theme_id="theme_presidential", alma_mater=["한국고등학교 32회"], source_url="https://dart.fss.or.kr")
    p3 = Person(id="P_003", name="이영수", category=PersonCategory.BUSINESSMAN, role_title="한양솔루션 의장", theme_id="theme_presidential", alma_mater=["서울대학교 법과대학"], source_url="https://dart.fss.or.kr")
    p4 = Person(id="P_004", name="최지연", category=PersonCategory.PUBLIC_OFFICIAL, role_title="태양메디컬 사외이사", theme_id="theme_presidential", source_url="https://dart.fss.or.kr")
    p5 = Person(id="P_005", name="정관우", category=PersonCategory.BUSINESSMAN, role_title="신라화학 총괄대표", theme_id="theme_presidential", source_url="https://dart.fss.or.kr")
    p6 = Person(id="P_006", name="오서진", category=PersonCategory.BUSINESSMAN, role_title="미래인포텍 대표", theme_id="theme_presidential", cohort_info="사법연수원 25기", source_url="https://dart.fss.or.kr")
    p8 = Person(id="P_008", name="한승우", category=PersonCategory.BUSINESSMAN, role_title="동서로지스 회장", theme_id="theme_presidential", source_url="https://dart.fss.or.kr")

    for p in [p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16]:
        engine.add_person(p)

    # ==========================================
    # 3. Companies (DART 전자공시 등록 상장사)
    # ==========================================
    c1 = Company(id="C_001", ticker="035420", name="대영테크", industry="스마트팩토리", current_price=42500, price_change_rate=8.42, market_cap="5,400억", dart_corp_code="00239102", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000102")
    c2 = Company(id="C_002", ticker="028050", name="한양솔루션", industry="신재생에너지/AI", current_price=15300, price_change_rate=12.30, market_cap="8,900억", dart_corp_code="00184920", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000280")
    c3 = Company(id="C_003", ticker="102930", name="태양메디컬", industry="바이오헬스", current_price=18200, price_change_rate=-1.35, market_cap="2,100억", dart_corp_code="00482910", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328001029")
    c4 = Company(id="C_004", ticker="009830", name="신라화학", industry="2차전지 소재", current_price=33000, price_change_rate=3.12, market_cap="1조 2,000억", dart_corp_code="00109283", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000983")
    c5 = Company(id="C_005", ticker="053800", name="미래인포텍", industry="AI 사이버보안", current_price=9800, price_change_rate=5.60, market_cap="3,800억", dart_corp_code="00392019", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000538")
    c6 = Company(id="C_006", ticker="001200", name="동서로지스", industry="스마트물류", current_price=24100, price_change_rate=-0.82, market_cap="6,700억", dart_corp_code="00112839", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000012")
    c7 = Company(id="C_007", ticker="094820", name="삼진네트웍스", industry="5G/통신장비", current_price=7800, price_change_rate=6.40, market_cap="3,100억", dart_corp_code="00592810", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000948")
    c8 = Company(id="C_008", ticker="012750", name="한성인프라", industry="도시재생/건설", current_price=21500, price_change_rate=4.80, market_cap="4,500억", dart_corp_code="00284918", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000127")
    c9 = Company(id="C_009", ticker="039240", name="미래핀테크", industry="디지털금융/보안", current_price=13400, price_change_rate=9.15, market_cap="5,200억", dart_corp_code="00472910", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000392")
    c10 = Company(id="C_010", ticker="063570", name="한국전자금융", industry="금융VAN/결제", current_price=8950, price_change_rate=3.40, market_cap="2,900억", dart_corp_code="00382910", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000635")
    c11 = Company(id="C_011", ticker="003490", name="대한홀딩스", industry="지주사/IT서비스", current_price=68000, price_change_rate=5.20, market_cap="3조 4,000억", dart_corp_code="00102938", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000034")
    c12 = Company(id="C_012", ticker="001740", name="대한물산", industry="종합상사/친환경", current_price=31200, price_change_rate=2.10, market_cap="1조 8,000억", dart_corp_code="00183920", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000017")
    c13 = Company(id="C_013", ticker="058470", name="케이반도체", industry="시스템반도체 IP", current_price=54000, price_change_rate=14.50, market_cap="2조 1,000억", dart_corp_code="00692810", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000584")
    c14 = Company(id="C_014", ticker="012450", name="글로벌방산통상", industry="방위산업/우주", current_price=41000, price_change_rate=7.80, market_cap="1조 4,000억", dart_corp_code="00294819", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000124")

    for c in [c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14]:
        engine.add_company(c)

    # ==========================================
    # 4. Relationships with DART Disclosure Fact Evidence
    # ==========================================
    # Theme 1: 김정치 (P_001)
    engine.add_relationship("P_001", "P_002", RelationType.HIGH_SCHOOL_ALUMNI, "한국고 32회 동창", source_url="https://open.assembly.go.kr")
    engine.add_relationship("P_002", "C_001", RelationType.CEO_OR_EXECUTIVE, "대표이사(지분 28.5%)", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000102")

    engine.add_relationship("P_001", "P_003", RelationType.UNIV_ALUMNI, "서울대 법대 동문", source_url="https://open.assembly.go.kr")
    engine.add_relationship("P_001", "P_003", RelationType.POLITICAL_CAMP, "미래혁신포럼 위원장", source_url="https://open.assembly.go.kr")
    engine.add_relationship("P_003", "C_002", RelationType.MAJOR_SHAREHOLDER, "최대주주 및 의장", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000280")
    engine.add_relationship("P_001", "C_002", RelationType.POLICY_THEME, "AI/에너지 육성 공약", source_url="https://open.assembly.go.kr")

    engine.add_relationship("P_001", "P_004", RelationType.SPOUSE_FAMILY, "처남 (인척관계)", source_url="https://open.assembly.go.kr")
    engine.add_relationship("P_004", "C_003", RelationType.OUTSIDE_DIRECTOR, "사외이사 재직", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328001029")

    engine.add_relationship("P_001", "P_005", RelationType.HOMETOWN_CONNECTION, "경북 안동 향우회", source_url="https://open.assembly.go.kr")
    engine.add_relationship("P_005", "C_004", RelationType.CEO_OR_EXECUTIVE, "총괄대표이사", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000983")

    engine.add_relationship("P_001", "P_006", RelationType.EXCLUSIVE_COHORT, "사법연수원 25기 동기", source_url="https://open.assembly.go.kr")
    engine.add_relationship("P_006", "C_005", RelationType.CEO_OR_EXECUTIVE, "대표이사 선임", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000538")

    engine.add_relationship("P_001", "P_007", RelationType.POLITICAL_CAMP, "선대위 총괄위원장", source_url="https://open.assembly.go.kr")
    engine.add_relationship("P_007", "P_008", RelationType.SPOUSE_FAMILY, "사돈 관계", source_url="https://www.moef.go.kr")
    engine.add_relationship("P_008", "C_006", RelationType.FOUNDER, "그룹 창업회장", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000012")

    # Theme 2: 이원내 (P_009) & 최격전 (P_010)
    engine.add_relationship("P_009", "C_007", RelationType.POLICY_THEME, "5G 전국망 특별법 발의", source_url="https://open.assembly.go.kr")
    engine.add_relationship("P_009", "P_002", RelationType.HOMETOWN_CONNECTION, "충남 향우회", source_url="https://open.assembly.go.kr")
    engine.add_relationship("P_010", "C_008", RelationType.POLICY_THEME, "인천 원도심 재개발 공약", source_url="https://www.nec.go.kr")
    engine.add_relationship("P_010", "C_007", RelationType.UNIV_ALUMNI, "고대 동문(대표)", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000948")

    # Theme 3: 한금융 (P_011) & 강법무 (P_012)
    engine.add_relationship("P_011", "C_009", RelationType.POLICY_THEME, "디지털금융 혁신 인가 수혜", source_url="https://www.fsc.go.kr")
    engine.add_relationship("P_011", "C_010", RelationType.UNIV_ALUMNI, "서울대 경제학과 동문(대표)", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000635")
    engine.add_relationship("P_012", "C_005", RelationType.EXCLUSIVE_COHORT, "사법연수원 23기 선후배", source_url="https://www.moj.go.kr")
    engine.add_relationship("P_012", "C_004", RelationType.HOMETOWN_CONNECTION, "TK 향우회 고문", source_url="https://www.moj.go.kr")

    # Theme 4: 정후계 (P_013) & 송고문 (P_014)
    engine.add_relationship("P_013", "C_011", RelationType.MAJOR_SHAREHOLDER, "대한홀딩스 지분 31.2%", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000034")
    engine.add_relationship("P_013", "C_012", RelationType.CEO_OR_EXECUTIVE, "대한물산 등기임원", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000017")
    engine.add_relationship("P_013", "P_014", RelationType.WORK_COLLEAGUE, "이사회 핵심 조력자", source_url="https://dart.fss.or.kr")
    engine.add_relationship("P_014", "C_011", RelationType.OUTSIDE_DIRECTOR, "이사회 의장(전 대법관)", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000034")

    # Theme 5: 조특사 (P_015) & 배사절 (P_016)
    engine.add_relationship("P_015", "P_016", RelationType.DIPLOMATIC_DELEGATION, "한미 경제사절단 공동단장", source_url="https://www.mofa.go.kr")
    engine.add_relationship("P_016", "C_013", RelationType.CEO_OR_EXECUTIVE, "케이반도체 창업대표", source_url="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240328000584")
    engine.add_relationship("P_015", "C_014", RelationType.POLICY_THEME, "글로벌 방산 수출 특사", source_url="https://www.mofa.go.kr")
