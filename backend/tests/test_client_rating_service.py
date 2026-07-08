from app.services.audit_service import should_audit
from app.services.client_rating_service import (
	rating_label_for,
	reliability_texts,
	risk_level_from_rating,
	visit_result_rating,
)


def test_risk_level_from_rating() -> None:
	assert risk_level_from_rating(4.5) == "low"
	assert risk_level_from_rating(3.5) == "medium"
	assert risk_level_from_rating(2.0) == "high"


def test_rating_label_for() -> None:
	assert rating_label_for(4.8) == "Отличный"
	assert rating_label_for(2.5) == "Ненадёжный"


def test_visit_result_rating_no_show() -> None:
	assert visit_result_rating("noShow", False, False, False) == 1.5


def test_visit_result_rating_positive_visit() -> None:
	rating = visit_result_rating("onTime", True, False, True)
	assert rating >= 4.5


def test_reliability_texts_reliable_client() -> None:
	title, subtitle = reliability_texts(4.5, 0, 0)
	assert "надёжный" in title
	assert "записи" in subtitle
