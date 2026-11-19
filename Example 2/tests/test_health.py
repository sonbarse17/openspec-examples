from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_ok(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "sqlite://")
    r = client.get("/health")
    assert r.status_code == 200 and r.json() == {"status": "ok"}


def test_health_db_down(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u:p@127.0.0.1:1/x")
    assert client.get("/health").status_code == 503
