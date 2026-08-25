#!/usr/bin/env bash
set -euo pipefail

# El servidor UBB está detrás de VPN, así que el despliegue se inicia desde
# el propio servidor: cada 2 minutos consulta main y despliega si cambió.

DEPLOY_PATH="${DEPLOY_PATH:-/srv/clase2taller}"
BRANCH="${DEPLOY_BRANCH:-main}"
LOCK_FILE="/tmp/clase2taller-auto-deploy.lock"
LAST_SHA_FILE="$DEPLOY_PATH/.last-deployed-sha"

cd "$DEPLOY_PATH"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  exit 0
fi

if ! git fetch origin "$BRANCH" --prune --quiet; then
  echo "[$(date -u +'%FT%TZ')] No se pudo consultar origin/$BRANCH." >&2
  exit 1
fi

REMOTE_SHA="$(git rev-parse "origin/$BRANCH")"
LAST_SHA=""
if [ -f "$LAST_SHA_FILE" ]; then
  LAST_SHA="$(cat "$LAST_SHA_FILE")"
fi

if [ "$REMOTE_SHA" = "$LAST_SHA" ]; then
  exit 0
fi

echo "[$(date -u +'%FT%TZ')] Nueva versión detectada: ${LAST_SHA:-<ninguna>} -> $REMOTE_SHA"

if DEPLOY_PATH="$DEPLOY_PATH" DEPLOY_BRANCH="$BRANCH" bash "$DEPLOY_PATH/scripts/deploy.sh"; then
  echo "$REMOTE_SHA" > "$LAST_SHA_FILE"
  echo "[$(date -u +'%FT%TZ')] Deploy automático OK."
else
  echo "[$(date -u +'%FT%TZ')] Validación/deploy FALLÓ; se mantendrá la versión anterior y se reintentará." >&2
  exit 1
fi
