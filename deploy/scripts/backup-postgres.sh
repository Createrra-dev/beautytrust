#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-/opt/beautytrust/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-deploy}"

mkdir -p "$BACKUP_DIR"
timestamp="$(date +%Y%m%d-%H%M)"
output_file="$BACKUP_DIR/beautytrust-${timestamp}.sql.gz"

cd "$ROOT_DIR"
docker compose -p "$COMPOSE_PROJECT" exec -T postgres \
	pg_dump -U beautytrust beautytrust | gzip > "$output_file"

find "$BACKUP_DIR" -name 'beautytrust-*.sql.gz' -mtime +"$RETENTION_DAYS" -delete
echo "Backup saved to $output_file"
