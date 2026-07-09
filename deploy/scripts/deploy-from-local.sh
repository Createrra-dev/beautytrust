#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

: "${SSH_HOST:?Set SSH_HOST, e.g. export SSH_HOST=5.42.107.134}"
: "${SSH_USER:?Set SSH_USER, e.g. export SSH_USER=root}"

run_ssh() {
	if [[ -n "${SSH_PASSWORD:-}" ]]; then
		command -v sshpass >/dev/null || {
			echo "Install sshpass: brew install hudochenkov/sshpass/sshpass" >&2
			exit 1
		}
		SSHPASS="$SSH_PASSWORD" sshpass -e ssh -o StrictHostKeyChecking=no "$@"
	else
		ssh -o StrictHostKeyChecking=no "$@"
	fi
}

run_rsync() {
	if [[ -n "${SSH_PASSWORD:-}" ]]; then
		SSHPASS="$SSH_PASSWORD" sshpass -e rsync -az -e "ssh -o StrictHostKeyChecking=no" "$@"
	else
		rsync -az -e "ssh -o StrictHostKeyChecking=no" "$@"
	fi
}

echo "Syncing project to ${SSH_USER}@${SSH_HOST}:/opt/beautytrust/"
run_rsync \
	--exclude '.git' \
	--exclude 'backend/.env' \
	--exclude 'deploy/.env' \
	--exclude 'backend/data/' \
	--exclude 'build/' \
	--exclude '.dart_tool/' \
	"$PROJECT_DIR/" "${SSH_USER}@${SSH_HOST}:/opt/beautytrust/"

echo "Rebuilding API on server..."
run_ssh "${SSH_USER}@${SSH_HOST}" \
	'cd /opt/beautytrust/deploy && docker compose up -d --build api redis nginx && docker compose ps'

echo "Done. Verify:"
echo "  curl -s https://apis.beautytrust.ru/openapi.json | grep yclients"
