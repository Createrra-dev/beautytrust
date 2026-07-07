import sqlite3
from pathlib import Path

from app.config import settings

_SCHEMA = """
CREATE TABLE IF NOT EXISTS payment_attempts (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	payment_id TEXT,
	order_id TEXT NOT NULL,
	amount INTEGER NOT NULL,
	description TEXT NOT NULL,
	status TEXT NOT NULL DEFAULT 'CREATED',
	success INTEGER NOT NULL DEFAULT 0,
	payment_url TEXT,
	return_result TEXT,
	last_error TEXT,
	tbank_response TEXT,
	created_at TEXT NOT NULL,
	updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_payment_attempts_payment_id
ON payment_attempts(payment_id);

CREATE INDEX IF NOT EXISTS idx_payment_attempts_order_id
ON payment_attempts(order_id);

CREATE INDEX IF NOT EXISTS idx_payment_attempts_created_at
ON payment_attempts(created_at DESC);
"""


def get_database_path() -> Path:
	database_path = Path(settings.database_path)
	if not database_path.is_absolute():
		database_path = Path(__file__).resolve().parents[2] / database_path
	database_path.parent.mkdir(parents=True, exist_ok=True)
	return database_path


def get_connection() -> sqlite3.Connection:
	connection = sqlite3.connect(get_database_path(), check_same_thread=False)
	connection.row_factory = sqlite3.Row
	return connection


def init_database() -> None:
	with get_connection() as connection:
		connection.executescript(_SCHEMA)
		connection.commit()
