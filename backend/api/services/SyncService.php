<?php
declare(strict_types=1);

require_once __DIR__ . '/../helpers/uuid.php';

final class SyncService
{
    public function __construct(private PDO $pdo) {}

    public function push(string $scope, string $deviceId, array $changes): array
    {
        $accepted = [];
        $conflicts = [];
        $rejected = [];

        $this->pdo->beginTransaction();
        try {
            foreach ($changes as $change) {
                try {
                    $result = $this->upsertChange($scope, $deviceId, $change);
                    if ($result['status'] === 'conflict') $conflicts[] = $result['data'];
                    else $accepted[] = $result['data'];
                } catch (Throwable $e) {
                    $rejected[] = [
                        'id' => $change['id'] ?? null,
                        'error' => $e->getMessage(),
                    ];
                }
            }
            $this->pdo->commit();
        } catch (Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }

        return compact('accepted', 'conflicts', 'rejected');
    }

    private function upsertChange(string $scope, string $deviceId, array $change): array
    {
        $entity = trim((string)($change['entity'] ?? ''));
        $recordId = trim((string)($change['recordId'] ?? $change['id'] ?? ''));
        $action = trim((string)($change['action'] ?? 'upsert'));
        $clientVersion = max(0, (int)($change['version'] ?? 0));
        $payload = $change['data'] ?? ($change['payload'] ?? []);

        if ($entity === '' || $recordId === '') {
            throw new InvalidArgumentException('Cada cambio necesita entity y recordId.');
        }
        if (!in_array($action, ['create', 'update', 'upsert', 'delete'], true)) {
            throw new InvalidArgumentException('Acción de sincronización no válida.');
        }

        $find = $this->pdo->prepare(
            'SELECT * FROM sync_records WHERE scope_key = ? AND entity = ? AND record_id = ? FOR UPDATE'
        );
        $find->execute([$scope, $entity, $recordId]);
        $existing = $find->fetch(PDO::FETCH_ASSOC);

        if ($existing && $clientVersion > 0 && $clientVersion < (int)$existing['version']) {
            return [
                'status' => 'conflict',
                'data' => [
                    'entity' => $entity,
                    'id' => $recordId,
                    'serverVersion' => (int)$existing['version'],
                    'serverData' => json_decode((string)$existing['payload'], true),
                    'action' => $existing['action'],
                ],
            ];
        }

        $newVersion = $existing ? ((int)$existing['version'] + 1) : 1;
        $json = json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($json === false) throw new RuntimeException('No se pudo serializar el cambio.');
        $checksum = hash('sha256', $json);

        if ($existing) {
            $stmt = $this->pdo->prepare(
                'UPDATE sync_records
                 SET device_id = ?, action = ?, version = ?, payload = ?, checksum = ?, updated_at = CURRENT_TIMESTAMP
                 WHERE id = ?'
            );
            $stmt->execute([$deviceId, $action, $newVersion, $json, $checksum, $existing['id']]);
        } else {
            $serverId = waiaUuid();
            $stmt = $this->pdo->prepare(
                'INSERT INTO sync_records
                 (id, scope_key, device_id, entity, record_id, action, version, payload, checksum)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([$serverId, $scope, $deviceId, $entity, $recordId, $action, $newVersion, $json, $checksum]);
        }

        return [
            'status' => 'accepted',
            'data' => [
                'entity' => $entity,
                'id' => $recordId,
                'version' => $newVersion,
                'action' => $action,
            ],
        ];
    }

    public function pull(string $scope, int $sinceVersion = 0, int $limit = 500): array
    {
        $limit = min(max($limit, 1), 1000);
        $stmt = $this->pdo->prepare(
            'SELECT entity, record_id, action, version, payload, updated_at
             FROM sync_records
             WHERE scope_key = ? AND version > ?
             ORDER BY version ASC, updated_at ASC
             LIMIT ' . $limit
        );
        $stmt->execute([$scope, $sinceVersion]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $changes = array_map(static function (array $row): array {
            return [
                'entity' => $row['entity'],
                'recordId' => $row['record_id'],
                'action' => $row['action'],
                'version' => (int)$row['version'],
                'data' => json_decode((string)$row['payload'], true),
                'updatedAt' => $row['updated_at'],
            ];
        }, $rows);

        $maxVersion = $sinceVersion;
        foreach ($changes as $change) $maxVersion = max($maxVersion, $change['version']);

        return [
            'changes' => $changes,
            'nextVersion' => $maxVersion,
            'hasMore' => count($changes) === $limit,
        ];
    }
}
