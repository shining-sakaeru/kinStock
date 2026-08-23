import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.services.dart_batch_sync import dart_batch_sync_service

client = TestClient(app)

def test_dart_batch_sync_pipeline():
    """Test DART batch sync and synapse cross-inference execution"""
    result = dart_batch_sync_service.run_sync_and_inference()
    assert result["status"] == "success"
    assert result["synced_companies_count"] > 0
    assert result["synced_persons_count"] > 0
    assert result["inferred_synapses_count"] >= 0

def test_get_company_synapse_network():
    """Test GET /api/v1/network/company/{corp_code}"""
    response = client.get("/api/v1/network/company/045660")
    assert response.status_code == 200
    data = response.json()
    assert data["focus_id"] == "C_045660"
    assert data["focus_type"] == "COMPANY"
    assert len(data["nodes"]) >= 1

def test_get_person_synapse_network():
    """Test GET /api/v1/network/person/{person_id}"""
    response = client.get("/api/v1/network/person/P_LEE_JM")
    assert response.status_code == 200
    data = response.json()
    assert data["focus_id"] == "P_LEE_JM"
    assert data["focus_type"] == "PERSON"
    assert len(data["nodes"]) >= 1

def test_find_synapse_path():
    """Test GET /api/v1/network/path?from={id}&to={id}"""
    response = client.get("/api/v1/network/path", params={"from": "P_LEE_JM", "to": "C_045660"})
    assert response.status_code == 200
    data = response.json()
    assert data["from_id"] == "P_LEE_JM"
    assert data["to_id"] == "C_045660"
    assert data["path_length"] >= 1
    assert len(data["steps"]) >= 1
    assert "evidence" in data["steps"][0]
