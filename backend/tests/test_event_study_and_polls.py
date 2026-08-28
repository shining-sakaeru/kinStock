import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_poll_leaderboard():
    """Test GET /api/v1/polls/leaderboard"""
    response = client.get("/api/v1/polls/leaderboard")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "latest_poll" in data
    assert "leaderboard" in data
    assert len(data["leaderboard"]) >= 5
    assert data["leaderboard"][0]["rank"] == 1
    assert "approval_rate" in data["leaderboard"][0]
    assert "delta_rate" in data["leaderboard"][0]
    assert "historical_trends" in data
    assert len(data["historical_trends"]) >= 2

def test_get_person_event_timeline():
    """Test GET /api/v1/events/timeline/{person_id}"""
    response = client.get("/api/v1/events/timeline/P_LEE_JM")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["total_events"] >= 1
    assert len(data["events"]) >= 1
    
    first_event = data["events"][0]
    assert "event_id" in first_event
    assert "title" in first_event
    assert "event_type" in first_event
    assert "occurred_at" in first_event
    assert "significance_score" in first_event
    assert "evidence_tier" in first_event
    assert "source_url" in first_event

def test_get_event_stock_impact():
    """Test GET /api/v1/analytics/stock-impact/{event_id}"""
    response = client.get("/api/v1/analytics/stock-impact/EVT_LEE_JM_2026_LEADERSHIP")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "event" in data
    assert data["total_affected_stocks"] >= 1
    assert "avg_d0_return" in data
    assert "avg_car_d5" in data
    
    stocks = data["stocks"]
    assert len(stocks) >= 1
    first_stock = stocks[0]
    assert "ticker" in first_stock
    assert "company_name" in first_stock
    assert "role_tier" in first_stock
    assert "d0_return" in first_stock
    assert "car_d5" in first_stock
    assert "volume_spike_ratio" in first_stock
    assert "market_reaction_grade" in first_stock
    assert "connection_hook" in first_stock
