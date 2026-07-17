#!/usr/bin/env python3
"""Import YClients fail_visits_count into client_profiles and print markdown table."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from sqlalchemy import select

from app.db import models
from app.db.session import SessionLocal
from app.services.yclients_service import import_yclients_client_no_shows


def main() -> int:
	master_id = int(sys.argv[1]) if len(sys.argv) > 1 else 2
	start_date = sys.argv[2] if len(sys.argv) > 2 else "2023-01-01"
	out_path = Path(sys.argv[3]) if len(sys.argv) > 3 else Path("/tmp/yclients_no_shows.md")

	db = SessionLocal()
	try:
		master = db.scalar(select(models.Master).where(models.Master.id == master_id))
		if master is None:
			print(f"Master {master_id} not found", file=sys.stderr)
			return 1

		rows = import_yclients_client_no_shows(db, master, start_date=start_date)
		with_fails = [row for row in rows if row["fail_visits_count"] > 0]

		lines = [
			"# Неявки клиентов из YClients",
			"",
			f"- Master ID: `{master.id}`",
			f"- Company ID: `{master.yclients_company_id}`",
			f"- Период записей: с `{start_date}`",
			f"- Уникальных клиентов (с валидным телефоном): **{len(rows)}**",
			f"- С неявками (`fail_visits_count` > 0): **{len(with_fails)}**",
			"",
			"| Клиент | Телефон | Неявки YClients |",
			"| --- | --- | ---: |",
		]
		for row in with_fails:
			phone = row["phone_digits"]
			formatted = f"+7{phone}"
			name = str(row["client_name"]).replace("|", "/")
			lines.append(f"| {name} | `{formatted}` | {row['fail_visits_count']} |")

		out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
		print(f"Wrote {out_path} ({len(with_fails)} clients with no-shows, {len(rows)} total)")
		return 0
	finally:
		db.close()


if __name__ == "__main__":
	raise SystemExit(main())
