import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_theme_stocks_ranking_and_causal_chain():
    """Test GET /api/v1/themes/stocks?person_id=... with Multi-Factor Global Metrics"""
    response = client.get("/api/v1/themes/stocks", params={"person_id": "P_LEE_JM"})
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["person_name"] == "이재명"
    assert data["total_stocks_count"] >= 1
    assert data["avg_kin_score"] > 0
    
    first_stock = data["stocks"][0]
    assert first_stock["rank"] == 1
    assert "stock_code" in first_stock
    assert "stock_name" in first_stock
    assert "kin_score" in first_stock
    
    # 5 Global Metrics
    metrics = first_stock["metrics"]
    assert "role_tier" in metrics
    assert "role_tier_label" in metrics
    assert "degree_of_sep" in metrics
    assert "degree_label" in metrics
    assert "factor_grade" in metrics
    assert "conviction_level" in metrics
    assert "causal_equation" in metrics
    
    # 3-Depth Causal Chain
    chain = first_stock["causal_chain"]
    assert "depth_1_hook" in chain
    assert "depth_2_path" in chain
    assert len(chain["depth_2_path"]) >= 3
    
    evidence = chain["depth_3_evidence"]
    assert evidence["source_name"] == "DART"
    assert "rcept_no" in evidence
    assert "report_name" in evidence
    assert "section" in evidence
    assert "snippet" in evidence
    assert "source_url" in evidence
