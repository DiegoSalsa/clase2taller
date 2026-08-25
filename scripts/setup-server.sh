#!/usr/bin/env bash
set -euo pipefail

# Bootstrap de una sola vez para el servidor UBB asignado a Diego (user9).
# Ejecutar como root dentro del servidor.

DEPLOY_USER="${DEPLOY_USER:-gpsuser9}"
DEPLOY_PATH="${DEPLOY_PATH:-/srv/clase2taller}"
REPO_URL="${REPO_URL:-https://github.com/DiegoSalsa/clase2taller.git}"
NODE_MAJOR="${NODE_MAJOR:-20}"
APP_PORT="${APP_PORT:-1546}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_USERNAME="${DB_USERNAME:-usergps9}"
DATABASE="${DATABASE:-usergps9_db}"

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: ejecuta este script como root (su -)." >&2
  exit 1
fi

if [ -z "${DB_PASSWORD:-}" ]; then
  read -r -s -p "Contraseña PostgreSQL para ${DB_USERNAME}: " DB_PASSWORD
  echo
fi

if [ -z "$DB_PASSWORD" ]; then
  echo "ERROR: la contraseña de PostgreSQL no puede estar vacía." >&2
  exit 1
fi

ACCESS_TOKEN_SECRET="${ACCESS_TOKEN_SECRET:-$(openssl rand -hex 32)}"
COOKIE_KEY="${COOKIE_KEY:-$(openssl rand -hex 32)}"
DEPLOY_HOME="$(getent passwd "$DEPLOY_USER" | cut -d: -f6)"

if [ -z "$DEPLOY_HOME" ]; then
  echo "ERROR: no existe el usuario $DEPLOY_USER en el servidor." >&2
  exit 1
fi

echo "==> Instalando dependencias del sistema"
apt-get update -qq
apt-get install -y -qq git curl ca-certificates build-essential openssl postgresql-client

CURRENT_NODE_MAJOR=0
if command -v node >/dev/null 2>&1; then
  CURRENT_NODE_MAJOR="$(node -p 'process.versions.node.split(`.`)[0]' 2>/dev/null || echo 0)"
fi

if [ "$CURRENT_NODE_MAJOR" -lt "$NODE_MAJOR" ]; then
  echo "==> Instalando Node.js ${NODE_MAJOR}"
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get install -y -qq nodejs
else
  echo "==> Node $(node -v) ya está instalado"
fi

if ! command -v pm2 >/dev/null 2>&1; then
  echo "==> Instalando PM2"
  npm install -g pm2
fi

echo "==> Preparando repositorio en $DEPLOY_PATH"
if [ ! -d "$DEPLOY_PATH/.git" ]; then
  mkdir -p "$(dirname "$DEPLOY_PATH")"
  git clone "$REPO_URL" "$DEPLOY_PATH"
fi
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_PATH"

runuser -u "$DEPLOY_USER" -- git -C "$DEPLOY_PATH" remote set-url origin "$REPO_URL"
runuser -u "$DEPLOY_USER" -- git -C "$DEPLOY_PATH" fetch origin --prune

if runuser -u "$DEPLOY_USER" -- git -C "$DEPLOY_PATH" show-ref --verify --quiet refs/remotes/origin/production; then
  runuser -u "$DEPLOY_USER" -- git -C "$DEPLOY_PATH" checkout -B production origin/production
else
  runuser -u "$DEPLOY_USER" -- git -C "$DEPLOY_PATH" checkout main
  echo "AVISO: la rama production todavía no existe; GitHub Actions la creará tras un CI exitoso."
fi

ENV_FILE="$DEPLOY_PATH/backend/src/config/.env"
echo "==> Creando $ENV_FILE sin guardar secretos en GitHub"
install -d -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" <<EOF
HOST=${DB_HOST}
PORT=${APP_PORT}
DB_USERNAME=${DB_USERNAME}
PASSWORD=${DB_PASSWORD}
DATABASE=${DATABASE}
ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
cookieKey=${COOKIE_KEY}
EOF
chown "$DEPLOY_USER:$DEPLOY_USER" "$ENV_FILE"
chmod 600 "$ENV_FILE"

echo "==> Probando conexión PostgreSQL"
if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USERNAME" -d "$DATABASE" -c 'SELECT 1;' >/dev/null 2>&1; then
  echo "    PostgreSQL OK"
else
  echo "AVISO: no se pudo validar PostgreSQL en ${DB_HOST}:5432. El deploy continuará; revisa el host de BD si el backend no inicia." >&2
fi

echo "==> Instalando cron de auto-deploy cada 2 minutos"
CRON_FILE="/etc/cron.d/clase2taller-auto-deploy"
cat > "$CRON_FILE" <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/2 * * * * ${DEPLOY_USER} cd ${DEPLOY_PATH} && DEPLOY_PATH=${DEPLOY_PATH} bash scripts/auto-deploy.sh >> /var/log/clase2taller-deploy.log 2>&1
EOF
chmod 0644 "$CRON_FILE"
touch /var/log/clase2taller-deploy.log
chown "$DEPLOY_USER:$DEPLOY_USER" /var/log/clase2taller-deploy.log

chmod +x "$DEPLOY_PATH/scripts/"*.sh 2>/dev/null || true

# Configura el servicio de resurrección de PM2 para este usuario.
pm2 startup systemd -u "$DEPLOY_USER" --hp "$DEPLOY_HOME" >/dev/null 2>&1 || true

if runuser -u "$DEPLOY_USER" -- git -C "$DEPLOY_PATH" show-ref --verify --quiet refs/remotes/origin/production; then
  echo "==> Ejecutando primer deploy"
  runuser -u "$DEPLOY_USER" -- env DEPLOY_PATH="$DEPLOY_PATH" bash "$DEPLOY_PATH/scripts/deploy.sh"
else
  echo "==> Primer deploy pendiente hasta que GitHub Actions cree production"
fi

echo
echo "=============================================="
echo "Servidor preparado para despliegue automático"
echo "Repo: $DEPLOY_PATH"
echo "API:  http://146.83.198.35:${APP_PORT}/api"
echo "Log:  /var/log/clase2taller-deploy.log"
echo "=============================================="
