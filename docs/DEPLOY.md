# Despliegue automático — clase2taller

El servidor UBB `146.83.198.35` está detrás de la VPN institucional. Por eso el despliegue usa un modelo **pull-based**: el servidor consulta GitHub desde dentro de la red y no necesita que GitHub entre por SSH.

## Flujo automático

1. Se hace `push` a `main`.
2. Cada 2 minutos, `scripts/auto-deploy.sh` consulta `origin/main`.
3. Si detecta un SHA nuevo, ejecuta `scripts/deploy.sh`.
4. El script instala dependencias y ejecuta `npm run lint` como gate de CI.
5. Si ESLint falla, **no se reinicia la aplicación** y el deploy queda rechazado.
6. Si la validación pasa, PM2 inicia o recarga `clase2taller-backend`.
7. Se ejecuta un smoke test HTTP y solo entonces se registra el SHA como desplegado.

La API queda expuesta en:

```text
http://146.83.198.35:1546/api
```

> También existe `.github/workflows/deploy.yml` como CI en GitHub. El despliegue del servidor no depende de que un runner de GitHub pueda alcanzar la red UBB.

## Configuración user9

- Puerto SSH: `1545`
- Puerto HTTP/API: `1546`
- Puerto HTTPS reservado: `1547`
- Usuario del servidor: `gpsuser9`
- Usuario PostgreSQL: `usergps9`
- Base de datos: `usergps9_db`

Las contraseñas **no se guardan en GitHub**. El bootstrap solicita la contraseña de PostgreSQL de forma interactiva y genera secretos aleatorios para JWT/cookies.

## Bootstrap inicial del servidor

Debe ejecutarse una sola vez desde un equipo conectado a la VPN UBB.

```bash
ssh -p 1545 gpsuser9@146.83.198.35
```

Después cambia a root con `su -` y ejecuta:

```bash
curl -fsSL https://raw.githubusercontent.com/DiegoSalsa/clase2taller/main/scripts/setup-server.sh -o /tmp/setup-server.sh
bash /tmp/setup-server.sh
```

El script:

- instala Git, Node.js 20, PM2 y el cliente PostgreSQL;
- clona `DiegoSalsa/clase2taller` en `/srv/clase2taller`;
- crea `backend/src/config/.env` con permisos `600`;
- prueba la conexión PostgreSQL;
- instala un cron de auto-deploy cada 2 minutos;
- configura PM2 para recuperarse tras reinicios;
- ejecuta el primer CI/deploy desde `main`.

## Monitoreo

```bash
tail -f /var/log/clase2taller-deploy.log
pm2 list
pm2 logs clase2taller-backend --lines 100
cat /srv/clase2taller/.last-deployed-sha
```

Para forzar una nueva validación y despliegue del último commit:

```bash
rm -f /srv/clase2taller/.last-deployed-sha
runuser -u gpsuser9 -- bash /srv/clase2taller/scripts/auto-deploy.sh
```

## Seguridad

No se deben subir al repositorio `.env`, contraseñas SSH, contraseña root ni contraseña de PostgreSQL. El repositorio público contiene solamente la automatización y los parámetros no secretos necesarios para identificar el entorno.
