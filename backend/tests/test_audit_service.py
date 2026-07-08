from app.services.audit_service import should_audit


def test_should_audit_mutations() -> None:
	assert should_audit("POST", "/api/appointments") is True
	assert should_audit("PATCH", "/api/profile") is True
	assert should_audit("GET", "/api/appointments") is False
	assert should_audit("POST", "/api/health") is False
	assert should_audit("POST", "/api/auth/otp/request") is False
