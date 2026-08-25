#!/usr/bin/env bash
set -euo pipefail

DEPLOY_PATH="${DEPLOY_PATH:-/srv/clase2taller}"
BRANCH="${DEPLOY_BRANCH:-main}"
PM2_NAME="${PM2_NAME:-clase2taller-backend}"

cd "$DEPLOY_PATH"

echo "============================================================"
echo "[$(date -u +'%FT%TZ')] Validando y desplegando origin/$BRANCH"
echo "============================================================"

git fetch origin "$BRANCH" --prune --quiet
git checkout -B "$BRANCH" "origin/$BRANCH" >/dev/null 2>&1
git reset --hard "origin/$BRANCH" >/dev/null

if [ ! -f backend/src/config/.env ]; then
  echo "ERROR: falta backend/src/config/.env. Ejecuta scripts/setup-server.sh primero." >&2
  exit 1
fi

echo "==> Instalando dependencias"
(
  cd backend
  # morgan está importado en runtime aunque actualmente figura en devDependencies,
  # por eso instalamos todas las dependencias.
  npm ci --silent
)

echo "==> CI: ejecutando ESLint"
(
  cd backend
  npm run lint
)

echo "==> CI OK; reiniciando backend con PM2"
if pm2 describe "$PM2_NAME" >/dev/null 2>&1; then
  pm2 reload "$PM2_NAME" --update-env
else
  pm2 start src/index.js \
    --name "$PM2_NAME" \
    --cwd "$DEPLOY_PATH/backend" \
    --update-env
fi
pm2 save >/dev/null

PORT="$(sed -n 's/^PORT=//p' backend/src/config/.env | tail -n 1)"
PORT="${PORT:-1546}"

sleep 3
if curl --max-time 5 --silent --show-error "http://127.0.0.1:${PORT}/api" >/dev/null; then
  echo "==> Smoke test HTTP OK en localhost:${PORT}"
else
  echo "ERROR: el backend no respondió en localhost:${PORT}." >&2
  pm2 logs "$PM2_NAME" --lines 40 --nostream || true
  exit 1
fi

echo "[$(date -u +'%FT%TZ')] CI/CD completado: $(git rev-parse --short HEAD)"
