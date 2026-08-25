# Despliegue automático — clase2taller

El servidor UBB `146.83.198.35` está detrás de la VPN institucional. Por eso el pipeline usa un modelo **pull-based** y no intenta hacer SSH desde GitHub Actions.

## Flujo

1. Se hace `push` a `main`.
2. GitHub Actions instala dependencias y ejecuta ESLint.
3. Solo si el CI termina correctamente, el workflow actualiza la rama `production` al commit validado.
4. El servidor consulta `production` cada 2 minutos mediante `scripts/auto-deploy.sh`.
5. Si detecta un SHA nuevo, ejecuta `scripts/deploy.sh`.
6. El backend se actualiza y PM2 lo reinicia automáticamente.

La API queda expuesta en:

```text
http://146.83.198.35:1546/api
```

## Configuración user9

- Puerto SSH externo: `1545`
- Puerto HTTP: `1546`
- Puerto HTTPS reservado: `1547`
- Usuario de servidor: `gpsuser9`
- Usuario PostgreSQL: `usergps9`
- Base de datos: `usergps9_db`

Las contraseñas **no se guardan en GitHub**. El bootstrap solicita la contraseña de PostgreSQL de forma interactiva y genera secretos aleatorios para JWT/cookies.

## Bootstrap inicial del servidor

Desde un equipo conectado a la VPN UBB:

```bash
ssh -p 1545 gpsuser9@146.83.198.35
```

Después cambia a root con `su -` y ejecuta:

```bash
curl -fsSL https://raw.githubusercontent.com/DiegoSalsa/clase2taller/main/scripts/setup-server.sh -o /tmp/setup-server.sh
bash /tmp/setup-server.sh
```

El script:

- instala Git, Node.js 20, PM2 y cliente PostgreSQL;
- clona `DiegoSalsa/clase2taller` en `/srv/clase2taller`;
- crea `backend/src/config/.env` con permisos `600`;
- prueba PostgreSQL;
- instala un cron de auto-deploy cada 2 minutos;
- configura PM2 para reinicios del servidor;
- ejecuta el primer deploy cuando `production` ya existe.

## Monitoreo

```bash
tail -f /var/log/clase2taller-deploy.log
pm2 list
pm2 logs clase2taller-backend --lines 100
cat /srv/clase2taller/.last-deployed-sha
```

Para forzar que el servidor vuelva a desplegar el último commit validado:

```bash
rm -f /srv/clase2taller/.last-deployed-sha
runuser -u gpsuser9 -- bash /srv/clase2taller/scripts/auto-deploy.sh
```

## Seguridad

No se deben subir al repositorio `.env`, contraseñas SSH, contraseña root ni contraseña de PostgreSQL. El repositorio público solo contiene nombres de usuario, puertos y scripts de automatización.
