import re

import bcrypt

_PASSWORD_HAS_DIGIT = re.compile(r"\d")
_PASSWORD_HAS_UPPER = re.compile(r"[A-ZА-Я]")
_EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def validate_password(password: str) -> None:
	if len(password) < 8:
		raise ValueError("Пароль должен быть не короче 8 символов")
	if _PASSWORD_HAS_DIGIT.search(password) is None:
		raise ValueError("Пароль должен содержать хотя бы одну цифру")
	if _PASSWORD_HAS_UPPER.search(password) is None:
		raise ValueError("Пароль должен содержать хотя бы одну заглавную букву")


def normalize_email(raw_email: str | None) -> str | None:
	if raw_email is None:
		return None

	email = raw_email.strip().lower()
	if not email:
		return None
	if _EMAIL_PATTERN.fullmatch(email) is None:
		raise ValueError("Некорректный email")
	return email


def hash_password(password: str) -> str:
	validate_password(password)
	password_bytes = password.encode("utf-8")
	return bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode("utf-8")
