<?php
declare(strict_types=1);

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/cors.php';
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/helpers/response.php';
require_once __DIR__ . '/middleware/security.php';
require_once __DIR__ . '/controllers/AuthController.php';
require_once __DIR__ . '/controllers/HostController.php';
require_once __DIR__ . '/controllers/ExperienceController.php';
require_once __DIR__ . '/controllers/SyncController.php';

$requestId = function_exists('waiaRequestId') ? waiaRequestId() : bin2hex(random_bytes(8));
header('X-WAIA-Request-Id: ' . $requestId);
waiaSecurityHeaders();

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
// Detectar la ruta real del directorio de la API en Apache/XAMPP.
$scriptName = str_replace('\\', '/', $_SERVER['SCRIPT_NAME'] ?? '');
$base = rtrim(str_replace('\\', '/', dirname($scriptName)), '/');
if ($base === '.' || $base === '/') $base = '';

// Comparar rutas sin depender de mayúsculas/minúsculas en Windows.
if ($base !== '' && (strcasecmp($uri, $base) === 0 || strncasecmp($uri, $base . '/', strlen($base) + 1) === 0)) {
    $path = substr($uri, strlen($base));
} else {
    $path = $uri;
}
$path = '/' . trim($path, '/');

try {
    if ($path === '/' && $method === 'GET') {
        waiaJson([
            'success' => true,
            'name' => 'WAIA API',
            'version' => '1.0.0-offline-first',
            'serverTime' => gmdate('c'),
            'sync' => '/sync',
        ]);
    }

    if ($path === '/health' && $method === 'GET') {
        $pdo->query('SELECT 1');
        waiaJson(['success' => true, 'database' => 'ok', 'serverTime' => gmdate('c')]);
    }

    if ($method === 'GET' && preg_match('#^/experiences(?:/(\\d+))?$#', $path, $matches)) {
        $controller = new ExperienceController($pdo);
        if (isset($matches[1]) && $matches[1] !== '') $controller->show((int)$matches[1]);
        $controller->index();
    }

    if (preg_match('#^/auth/(register|login|logout|me|refresh)$#', $path, $matches)) {
        $authAction = $matches[1];
        if (in_array($authAction, ['logout', 'refresh'], true) && $method === 'POST') waiaRequireCsrf();
        (new AuthController($pdo))->handle($authAction, $method);
    }

    if ($path === '/sync') {
        $user = waiaRequireAuth();
        if ($method === 'POST') waiaRequireCsrf();
        (new SyncController($pdo))->handle($method, $user);
    }

    if (preg_match('#^/host/(dashboard|experiences)$#', $path, $matches)) {
        $user = waiaRequireAuth();
        if ($method !== 'GET') waiaRequireCsrf();
        (new HostController($pdo))->handle($matches[1], $method, $user);
    }

    waiaError('Ruta no encontrada.', 404, ['path' => $path]);
} catch (Throwable $e) {
    error_log('[WAIA API ERROR] ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
    if (defined('APP_DEBUG') && APP_DEBUG) {
        waiaError($e->getMessage(), 500, ['exception' => get_class($e)]);
    }
    waiaError('Error interno del servidor.', 500);
}
