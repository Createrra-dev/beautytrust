#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-deploy}"

cd "$ROOT_DIR"
docker compose -p "$COMPOSE_PROJECT" run --rm --entrypoint certbot certbot renew --quiet
docker compose -p "$COMPOSE_PROJECT" exec nginx nginx -s reload
echo "SSL certificates renewed"
