#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_DIR="$ROOT_DIR/deploy"
EMAIL="${CERTBOT_EMAIL:-admin@beautytrust.ru}"

if ! command -v docker >/dev/null; then
	apt-get update
	apt-get install -y ca-certificates curl gnupg
	install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	chmod a+r /etc/apt/keyrings/docker.gpg
	echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
		$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
		> /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

cd "$DEPLOY_DIR"
cp -n .env.example .env || true
cp nginx/nginx.bootstrap.conf nginx/nginx.active.conf

docker compose down || true
docker compose up -d --build

echo "Waiting for services..."
sleep 15

docker compose run --rm --entrypoint certbot certbot certonly \
	--webroot -w /var/www/certbot \
	-d beautytrust.ru -d www.beautytrust.ru -d apis.beautytrust.ru \
	--email "$EMAIL" --agree-tos --no-eff-email --non-interactive || true

if docker compose run --rm --entrypoint certbot certbot certificates 2>/dev/null | grep -q beautytrust.ru; then
	cp nginx/nginx.conf nginx/nginx.active.conf
	docker compose restart nginx
fi

docker compose ps
