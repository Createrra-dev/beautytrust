#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MARKER="# beautytrust-cron"

backup_cron="15 3 * * * cd $ROOT_DIR && bash scripts/backup-postgres.sh >> /var/log/beautytrust-backup.log 2>&1"
renew_cron="30 4 * * 1 cd $ROOT_DIR && bash scripts/renew-ssl.sh >> /var/log/beautytrust-ssl.log 2>&1"

existing="$(crontab -l 2>/dev/null || true)"
filtered="$(printf '%s\n' "$existing" | grep -v "$MARKER" || true)"

{
	printf '%s\n' "$filtered"
	echo "$backup_cron $MARKER-backup"
	echo "$renew_cron $MARKER-ssl"
} | crontab -

echo "Cron jobs installed:"
crontab -l | grep "$MARKER" || true
