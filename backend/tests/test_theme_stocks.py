import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_theme_stocks_ranking_and_causal_chain():
    """Test GET /api/v1/themes/stocks?person_id=..."""
    response = client.get("/api/v1/themes/stocks", params={"person_id": "P_LEE_JM"})
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["person_name"] == "이재명"
    assert data["total_stocks_count"] >= 1
    assert data["avg_kin_score"] > 0
    
    first_stock = data["stocks"][0]
    assert first_stock["rank"] == 1
    assert "kin_score" in first_stock
    assert "theme_tier" in first_stock
    assert "depth1_hook" in first_stock
    assert "depth2_causal_chain" in first_stock
    assert "depth3_evidence" in first_stock
    assert "trading_metrics" in first_stock
    
    chain = first_stock["depth2_causal_chain"]
    assert "source_person" in chain
    assert "p2p_edge" in chain
    assert "intermediary_person" in chain
    assert "p2c_edge" in chain
    assert "target_company" in chain
    
    evidence = first_stock["depth3_evidence"]
    assert "dart_filing_title" in evidence
    assert "rcp_no" in evidence
    assert "dart_url" in evidence
