import pytest
from fastapi.testclient import TestClient
from app.domain.entities.weight_settings import WeightSettings
from app.domain.entities.relationship import NetworkEdge, RelationType
from app.domain.services.scoring_engine import (
    calculate_single_path_score,
    calculate_aggregated_relevance,
    format_path_summary
)
from app.main import app

client = TestClient(app)

def test_pure_domain_scoring_engine_calculation():
    weights = WeightSettings(
        executive_family=0.95,
        exclusive_cohort=0.85,
        direct_alumni=0.70,
        regional_ties=0.45,
        decay_factor=0.60
    )
    
    # Path: P1 -(Alumni: 0.70)-> P2 -(CEO: 0.95 * 1.3 => 1.0)-> C1
    edge1 = NetworkEdge(
        source_id="P1", target_id="P2", relation_type=RelationType.HIGH_SCHOOL_ALUMNI,
        label="고교동문", badge="고교동문", base_weight=0.70, source_url="http://test"
    )
    edge2 = NetworkEdge(
        source_id="P2", target_id="C1", relation_type=RelationType.CEO_OR_EXECUTIVE,
        label="대표이사", badge="대표이사", base_weight=0.95, source_url="http://test"
    )
    
    # 2-hop score: (0.70 * 1.0) * (0.60^1) = 0.42
    score = calculate_single_path_score([edge1, edge2], weights)
    assert round(score, 4) == 0.4200
    
    relevance = calculate_aggregated_relevance([score])
    assert relevance == 42.0
    
    badge, summary = format_path_summary("이재명", None, "에이텍", ["성남 창조경영 CEO포럼 연계"], 1)
    assert "성남 창조경영" in badge
    assert "에이텍" in summary

def test_universal_search_api():
    # 1. Search with "이재명" (Person)
    res = client.get("/api/v1/search?q=이재명")
    assert res.status_code == 200
    data = res.json()
    assert data["total_count"] >= 1
    assert any(r["type"] == "PERSON" and r["title"] == "이재명" for r in data["results"])

    # 2. Search with "안랩" (Stock)
    res_stock = client.get("/api/v1/search?q=안랩")
    assert res_stock.status_code == 200
    data_stock = res_stock.json()
    assert data_stock["total_count"] >= 1
    assert any(r["type"] == "STOCK" and r["title"] == "안랩" for r in data_stock["results"])

    # 3. Search with "대선" (Theme)
    res_theme = client.get("/api/v1/search?q=대선")
    assert res_theme.status_code == 200
    data_theme = res_theme.json()
    assert data_theme["total_count"] >= 1
    assert any(r["type"] == "THEME" and "대선" in r["title"] for r in data_theme["results"])

def test_mode_c_theme_cluster_api():
    res = client.get("/api/v1/themes/theme_presidential/cluster")
    assert res.status_code == 200
    data = res.json()
    assert data["theme"]["title"] == "대선 테마"
    assert len(data["key_figures"]) >= 2
    assert len(data["top_theme_stocks"]) >= 2

def test_person_and_stock_hub_apis():
    # Mode A: Person-Hub
    res_a = client.get("/api/v1/figures/P_LEE_JM/stocks")
    assert res_a.status_code == 200
    data_a = res_a.json()
    assert data_a["figure"]["name"] == "이재명"
    assert len(data_a["recommendations"]) >= 2

    # Mode B: Stock-Hub
    res_b = client.get("/api/v1/stocks/045660/figures")
    assert res_b.status_code == 200
    data_b = res_b.json()
    assert data_b["company"]["ticker"] == "045660"
    assert len(data_b["related_figures"]) >= 1

def test_tier_2_deep_dive_relation_detail():
    res = client.get("/api/v1/relations/detail?source_id=P_LEE_JM&target_id=C_045660")
    assert res.status_code == 200
    data = res.json()
    assert data["source_person"]["name"] == "이재명"
    assert data["target_company"]["name"] == "에이텍"
    assert data["investment_rationale"] is not None
    assert len(data["investment_rationale"]["executive_power_analysis"]) > 10
    assert "https://dart.fss.or.kr" in data["dart_fact"]["source_url"]

def test_weights_baseline_api():
    res = client.get("/api/v1/weights/baseline")
    assert res.status_code == 200
    data = res.json()
    assert "executive_family" in data["factors"]
    assert data["factors"]["executive_family"]["default_value"] == 0.95
