# WAIA - Integración Offline-First + API + MySQL

Esta primera capa **no elimina localStorage**. Las operaciones existentes siguen guardándose localmente y, además, generan una cola de sincronización en IndexedDB.

## 1. Base de datos

Ejecuta primero:

```sql
SOURCE database/schema/waia_database.sql;
SOURCE database/migrations/001_offline_first_sync.sql;
```

## 2. API

En XAMPP coloca el proyecto en:

`C:/xampp/htdocs/waia`

La API queda en:

`http://localhost/waia/backend/api`

Comprueba:

- `GET /health`
- `GET /`

## 3. Frontend

Copia el `.env.example` como `.env` y ejecuta:

```bash
npm install
npm run dev
```

## 4. Qué ocurre al guardar

React conserva la información en localStorage como antes. Además, `api.js` crea una operación pendiente en IndexedDB. `syncManager.js` intenta enviarla a `POST /sync` cuando hay conexión y vuelve a intentar automáticamente cada 30 segundos.

## 5. Importante

La tabla `sync_records` es la capa de respaldo/sincronización inicial. En esta fase no sustituye todavía las tablas normalizadas de WAIA. El siguiente paso es conectar cada entidad sincronizada con sus tablas `users`, `bookings`, `favorites`, `experiences`, etc., después de definir las reglas de autenticación y conflictos.

No pongas secretos de servidor en el frontend. La seguridad de producción debe agregar autenticación de usuario y autorización en `/sync`.
