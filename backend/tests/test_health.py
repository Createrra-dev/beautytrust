from fastapi.testclient import TestClient

from app.config import settings
from app.main import app


def test_api_health() -> None:
	with TestClient(app) as client:
		response = client.get("/api/health")
		assert response.status_code == 200
		assert response.json()["status"] == "ok"


def test_metrics_requires_token(monkeypatch) -> None:
	monkeypatch.setattr(settings, "metrics_token", "secret-metrics")
	monkeypatch.setattr(settings, "admin_token", "")

	with TestClient(app) as client:
		assert client.get("/metrics").status_code == 401
		response = client.get("/metrics", headers={"X-Metrics-Token": "secret-metrics"})
		assert response.status_code == 200
		assert "python_info" in response.text
