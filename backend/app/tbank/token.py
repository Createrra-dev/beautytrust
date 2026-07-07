import hashlib
from typing import Any


def generate_token(payload: dict[str, Any], password: str) -> str:
	sign_payload: dict[str, Any] = {
		key: value
		for key, value in payload.items()
		if key != "Token" and not isinstance(value, (dict, list))
	}
	sign_payload["Password"] = password

	concatenated = "".join(
		str(sign_payload[key])
		for key in sorted(sign_payload.keys())
	)
	return hashlib.sha256(concatenated.encode("utf-8")).hexdigest()
