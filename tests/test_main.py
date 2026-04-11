from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_create_todo():
    response = client.post("/todos", json={"title": "learn pytest", "done": False})
    assert response.status_code == 201

    body = response.json()
    assert body["title"] == "learn pytest"
    assert body["done"] is False
    assert "id" in body