from app.services.audit_service import should_audit
from app.services.client_rating_service import (
	appointment_score_from_profile,
	rating_label_for,
	reliability_texts,
	risk_level_for_client,
	risk_level_from_rating,
	visit_result_rating,
)


def test_risk_level_from_rating() -> None:
	assert risk_level_from_rating(4.5) == "low"
	assert risk_level_from_rating(3.5) == "medium"
	assert risk_level_from_rating(2.0) == "high"


def test_risk_level_for_client_uses_no_shows() -> None:
	assert risk_level_for_client(4.5, no_shows=0) == "low"
	assert risk_level_for_client(3.5, no_shows=1) == "medium"
	assert risk_level_for_client(3.5, no_shows=3) == "high"
	assert risk_level_for_client(4.8, no_shows=0, scandals=2) == "high"


def test_appointment_score_penalizes_no_shows() -> None:
	class _Profile:
		reviews_average = 3.5
		no_shows_count = 5
		scandals_count = 0

	rating, risk = appointment_score_from_profile(_Profile())  # type: ignore[arg-type]
	assert risk == "high"
	assert rating <= 2.0


def test_rating_label_for() -> None:
	assert rating_label_for(4.8) == "Отличный"
	assert rating_label_for(2.5) == "Ненадёжный"


def test_visit_result_rating_no_show() -> None:
	assert visit_result_rating("noShow", False, False, False, False, False, False, False, False) == 1.5


def test_visit_result_rating_positive_visit() -> None:
	rating = visit_result_rating("onTime", True, False, False, False, False, False, False, True)
	assert rating >= 4.5


def test_visit_result_rating_behavior_issues() -> None:
	rating = visit_result_rating(
		"onTime",
		True,
		True,
		False,
		True,
		False,
		False,
		False,
		False,
	)
	assert rating < 4.0


def test_reliability_texts_reliable_client() -> None:
	title, subtitle = reliability_texts(4.5, 0, 0)
	assert "надёжный" in title
	assert "записи" in subtitle
