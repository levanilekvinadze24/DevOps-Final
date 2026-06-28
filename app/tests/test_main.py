import json

import pytest

from main import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_index(client):
    response = client.get("/")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "running"


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "healthy"


def test_ready(client):
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.get_json()["status"] == "ready"


def test_metrics(client):
    client.get("/api/data")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"app_requests_total" in response.data


def test_api_data(client):
    response = client.get("/api/data")
    assert response.status_code == 200
    data = response.get_json()
    assert len(data["items"]) == 5


def test_api_error(client):
    response = client.get("/api/error")
    assert response.status_code == 500
    assert response.get_json()["error"] == "simulated failure"


def test_api_error_bulk(client):
    response = client.get("/api/error/bulk?count=3")
    assert response.status_code == 500
    assert response.get_json()["errors_generated"] == 3
