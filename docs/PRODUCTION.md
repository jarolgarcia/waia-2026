# Producción WAIA

La arquitectura de producción es:

`Internet → Nginx → frontend estático / PHP-FPM → MySQL privado`

Nginx es el único servicio con puerto público. El código PHP vive solamente en el contenedor `api`; MySQL no publica ningún puerto. Los contenedores usan `no-new-privileges`, el API corre como `www-data` y Nginx usa una imagen sin privilegios.

## Configuración

1. Copia `.env.production.example` a `.env.production` en el servidor.
2. Cambia `APP_SECRET`, `DB_PASSWORD` y `DB_ROOT_PASSWORD` por valores aleatorios fuertes.
3. Configura el dominio real en `API_BASE_URL` y `CORS_ORIGINS`.
4. Usa HTTPS delante del puerto 80 o añade certificados TLS en Nginx antes de producción. `SESSION_SECURE_COOKIE=true` requiere HTTPS.

## Verificación

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml config
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build
curl -fsS https://waia.example.com/health
curl -fsS https://waia.example.com/api/health
docker compose -f docker-compose.prod.yml ps
```

No se deben abrir los puertos 3306 ni 9000 en Azure. Las copias de seguridad de MySQL deben configurarse fuera del contenedor y probarse periódicamente.
