<?php
declare(strict_types=1);

require_once __DIR__ . '/../helpers/request.php';
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../services/SyncService.php';

final class SyncController
{
    public function __construct(private PDO $pdo) {}

    public function handle(string $method, array $user = []): never
    {
        $deviceId = waiaHeader('X-WAIA-Device');
        if (!$deviceId) waiaError('Falta X-WAIA-Device.', 400);
        if (strlen($deviceId) > 100) waiaError('Device ID demasiado largo.', 400);

        $body = waiaJsonBody();
        $scope = $user ? 'user:' . (int)$user['id'] : trim((string)($body['scope'] ?? 'device:' . $deviceId));
        if ($scope === '' || strlen($scope) > 190) waiaError('Scope inválido.', 400);

        $service = new SyncService($this->pdo);

        if ($method === 'POST') {
            $changes = $body['changes'] ?? [];
            if (!is_array($changes)) waiaError('changes debe ser un arreglo.', 400);
            $result = $service->push($scope, $deviceId, array_slice($changes, 0, 500));
            $pull = $service->pull($scope, (int)($body['sinceVersion'] ?? 0));
            waiaJson([
                'success' => true,
                'serverTime' => gmdate('c'),
                ...$result,
                'pull' => $pull,
            ]);
        }

        if ($method === 'GET') {
            $since = max(0, (int)($_GET['since'] ?? 0));
            $pull = $service->pull($scope, $since);
            waiaJson(['success' => true, 'serverTime' => gmdate('c'), 'pull' => $pull]);
        }

        waiaError('Método no permitido.', 405, ['allowed' => ['GET', 'POST']]);
    }
}
