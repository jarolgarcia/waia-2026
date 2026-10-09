<?php
declare(strict_types=1);

require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../models/Experience.php';

final class ExperienceController
{
    public function __construct(private PDO $pdo) {}

    public function index(): never
    {
        $model = new Experience($this->pdo);
        $search = trim((string)($_GET['q'] ?? $_GET['search'] ?? ''));
        $category = trim((string)($_GET['category'] ?? ''));
        $department = trim((string)($_GET['department'] ?? ''));
        $limit = min(max((int)($_GET['limit'] ?? 12), 1), 100);
        $page = max((int)($_GET['page'] ?? 1), 1);
        $offset = ($page - 1) * $limit;

        $categoryId = $category !== '' && strtolower($category) !== 'todas' ? $this->lookupId('categories', $category) : null;
        $departmentId = $department !== '' ? $this->lookupId('departments', $department) : null;
        $rows = $model->getAll($search !== '' ? $search : null, $categoryId, $departmentId, $limit, $offset);
        $total = $model->count($search !== '' ? $search : null, $categoryId, $departmentId);
        waiaJson(['success' => true, 'data' => array_map([$this, 'present'], $rows), 'total' => $total, 'page' => $page, 'limit' => $limit]);
    }

    public function show(int $id): never
    {
        $stmt = $this->pdo->prepare('SELECT e.id, e.title, e.slug, e.short_description AS shortDescription, e.long_description AS longDescription, e.location, e.duration_minutes AS durationMinutes, e.max_participants AS capacity, e.price_usd AS price, e.price_nio AS priceNio, e.latitude, e.longitude, e.main_image_url AS imageUrl, c.name AS category, d.name AS department, h.name AS host FROM experiences e INNER JOIN categories c ON c.id = e.category_id INNER JOIN departments d ON d.id = e.department_id LEFT JOIN hosts h ON h.id = e.host_id WHERE e.id = ? AND e.status = \'published\' LIMIT 1');
        $stmt->execute([$id]);
        $experience = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$experience) waiaError('Experiencia no encontrada.', 404);
        waiaJson(['success' => true, 'data' => $experience]);
    }

    private function present(array $row): array
    {
        return [
            'id' => (int)$row['id'],
            'title' => $row['title'],
            'slug' => $row['slug'],
            'shortDescription' => $row['short_description'] ?? '',
            'longDescription' => $row['long_description'] ?? '',
            'location' => $row['location'] ?? '',
            'duration' => $row['duration_minutes'] ? ((int)$row['duration_minutes'] . ' minutos') : 'Por confirmar',
            'capacity' => (int)($row['max_participants'] ?? 0),
            'price' => (float)($row['price_usd'] ?? 0),
            'priceLabel' => 'Desde',
            'imageUrl' => $row['main_image_url'] ?? $row['imageUrl'] ?? '',
            'latitude' => $row['latitude'] !== null ? (float)$row['latitude'] : null,
            'longitude' => $row['longitude'] !== null ? (float)$row['longitude'] : null,
            'category' => $row['category_name'] ?? '',
            'categoryLabel' => $row['category_name'] ?? '',
            'department' => $row['department_name'] ?? '',
            'host' => $row['host_name'] ?? 'Anfitrión WAIA',
            'isDemo' => false,
        ];
    }

    private function lookupId(string $table, string $name): ?int
    {
        if (!in_array($table, ['categories', 'departments'], true)) return null;
        $stmt = $this->pdo->prepare("SELECT id FROM {$table} WHERE name = ? LIMIT 1");
        $stmt->execute([$name]);
        $id = $stmt->fetchColumn();
        return $id === false ? null : (int)$id;
    }
}
