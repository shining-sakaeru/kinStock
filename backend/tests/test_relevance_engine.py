import pytest
from app.core.graph_engine import GraphEngine
from app.core.models import Person, Company, PersonCategory, RelationType, AI_DEFAULT_WEIGHTS
from app.services.relevance_service import relevance_service
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_engine_weight_decay_calculation_with_ai_defaults():
    engine = GraphEngine()
    p1 = Person(id="TP1", name="테스트1", category=PersonCategory.POLITICIAN, role_title="의원", source_url="https://open.assembly.go.kr")
    p2 = Person(id="TP2", name="테스트2", category=PersonCategory.BUSINESSMAN, role_title="임원", source_url="https://dart.fss.or.kr")
    c1 = Company(id="TC1", ticker="000001", name="테스트기업", industry="IT", current_price=1000, price_change_rate=1.0, market_cap="100억", dart_corp_code="00102938")
    
    engine.add_person(p1)
    engine.add_person(p2)
    engine.add_company(c1)
    
    engine.add_relationship("TP1", "TP2", RelationType.HIGH_SCHOOL_ALUMNI, source_url="https://open.assembly.go.kr")
    engine.add_relationship("TP2", "TC1", RelationType.CEO_OR_EXECUTIVE, source_url="https://dart.fss.or.kr")
    
    recs = engine.calculate_recommendations("TP1")
    assert recs is not None
    assert len(recs.recommendations) == 1
    assert recs.recommendations[0].relevance_score == 39.9
    assert recs.recommendations[0].depth == 2
    assert recs.recommendations[0].dart_fact is not None
    assert "https://dart.fss.or.kr" in recs.recommendations[0].source_url

def test_stock_centric_reverse_calculation():
    engine = GraphEngine()
    p1 = Person(id="TP1", name="김정치", category=PersonCategory.POLITICIAN, role_title="대선후보", theme_id="theme_presidential")
    p2 = Person(id="TP2", name="박대표", category=PersonCategory.BUSINESSMAN, role_title="대표이사")
    c1 = Company(id="TC1", ticker="035420", name="대영테크", industry="스마트팩토리", current_price=1000, price_change_rate=1.0, market_cap="100억")

    engine.add_person(p1)
    engine.add_person(p2)
    engine.add_company(c1)

    engine.add_relationship("TP1", "TP2", RelationType.HIGH_SCHOOL_ALUMNI)
    engine.add_relationship("TP2", "TC1", RelationType.CEO_OR_EXECUTIVE)

    # Reverse lookup from Company TC1
    res = engine.calculate_stock_related_figures("TC1")
    assert res is not None
    assert res.company.name == "대영테크"
    assert len(res.related_figures) == 2
    figure_names = [f.name for f in res.related_figures]
    assert "박대표" in figure_names
    assert "김정치" in figure_names
    assert res.related_figures[0].name == "박대표"
    assert res.related_figures[0].relevance_score == 95.0
    assert res.related_figures[1].name == "김정치"
    assert res.related_figures[1].relevance_score == 39.9

def test_api_bidirectional_and_relation_detail():
    # 1. GET /api/v1/stocks
    res_stocks = client.get("/api/v1/stocks")
    assert res_stocks.status_code == 200
    stocks = res_stocks.json()
    assert len(stocks) >= 5

    # 2. GET /api/v1/stocks/045660/related-figures (Stock-Centric API)
    res_fig = client.get("/api/v1/stocks/045660/related-figures")
    assert res_fig.status_code == 200
    fig_data = res_fig.json()
    assert fig_data["company"]["ticker"] == "045660"
    assert len(fig_data["related_figures"]) > 0

    # 3. GET /api/v1/relations/detail?source_id=P_LEE_JM&target_id=C_045660
    res_detail = client.get("/api/v1/relations/detail?source_id=P_LEE_JM&target_id=C_045660")
    assert res_detail.status_code == 200
    detail_data = res_detail.json()
    assert detail_data["investment_rationale"] is not None
    assert len(detail_data["investment_rationale"]["executive_power_analysis"]) > 10
