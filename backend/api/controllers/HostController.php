<?php
declare(strict_types=1);

require_once __DIR__ . '/../helpers/request.php';
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../middleware/security.php';

final class HostController
{
    public function __construct(private PDO $pdo) {}

    public function handle(string $resource, string $method, array $user): never
    {
        $host = $this->hostForUser($user);
        if (!$host) waiaError('La cuenta no tiene un perfil de anfitrión.', 403);
        if ($resource === 'dashboard' && $method === 'GET') $this->dashboard((int)$host['id']);
        if ($resource === 'experiences' && $method === 'POST') $this->createExperience((int)$host['id']);
        waiaError('Método no permitido.', 405);
    }

    private function hostForUser(array $user): ?array
    {
        $userId = (int)($user['id'] ?? 0);
        $role = strtolower(trim((string)($user['role'] ?? '')));
        if ($userId < 1 || !in_array($role, ['host', 'anfitrion', 'anfitrión', 'admin'], true)) return null;

        $stmt = $this->pdo->prepare('SELECT id, user_id, name, bio, email FROM hosts WHERE user_id = ? AND status = \'active\' LIMIT 1');
        $stmt->execute([$userId]);
        $host = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($host) return $host;

        // Repara cuentas host antiguas que no tienen fila en hosts.
        $name = trim((string)($user['name'] ?? '')) ?: 'Anfitrion WAIA';
        $email = strtolower(trim((string)($user['email'] ?? '')));
        $create = $this->pdo->prepare('INSERT INTO hosts (user_id, name, email, status) VALUES (?, ?, ?, \'active\')');
        $create->execute([$userId, $name, $email]);
        $hostId = (int)$this->pdo->lastInsertId();

        $stmt = $this->pdo->prepare('SELECT id, user_id, name, bio, email FROM hosts WHERE id = ? LIMIT 1');
        $stmt->execute([$hostId]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    private function dashboard(int $hostId): never
    {
        $experienceStmt = $this->pdo->prepare('SELECT id, title, location, short_description AS shortDescription, price_usd AS price, status FROM experiences WHERE host_id = ? ORDER BY created_at DESC');
        $experienceStmt->execute([$hostId]);
        $experiences = $experienceStmt->fetchAll(PDO::FETCH_ASSOC);
        $bookingStmt = $this->pdo->prepare('SELECT b.id, e.title AS experienceTitle, b.booking_date AS date, b.participants AS guests, b.status, b.total_usd AS price FROM bookings b INNER JOIN experiences e ON e.id = b.experience_id WHERE e.host_id = ? ORDER BY b.created_at DESC');
        $bookingStmt->execute([$hostId]);
        $bookings = $bookingStmt->fetchAll(PDO::FETCH_ASSOC);
        $revenue = 0.0;
        foreach ($bookings as $booking) if ($booking['status'] === 'confirmed') $revenue += (float)($booking['price'] ?? 0);
        $hostStmt = $this->pdo->prepare('SELECT id, user_id, name, bio, email FROM hosts WHERE id = ?');
        $hostStmt->execute([$hostId]);
        waiaJson(['success' => true, 'host' => $hostStmt->fetch(PDO::FETCH_ASSOC), 'experiences' => $experiences, 'bookings' => $bookings, 'revenue' => $revenue]);
    }

    private function createExperience(int $hostId): never
    {
        $body = str_contains(strtolower((string)($_SERVER['CONTENT_TYPE'] ?? '')), 'application/json') ? waiaJsonBody() : $_POST;
        $title = trim((string)($body['title'] ?? ''));
        $location = trim((string)($body['location'] ?? ''));
        $shortDescription = trim((string)($body['shortDescription'] ?? ''));
        if (mb_strlen($title) < 5 || $location === '' || mb_strlen($shortDescription) < 10) waiaError('Completa título, ubicación y descripción de la experiencia.', 422);
        $latitude = $this->coordinate($body['latitude'] ?? null, -90, 90);
        $longitude = $this->coordinate($body['longitude'] ?? null, -180, 180);
        $imageUrl = $this->storeImage($_FILES['image'] ?? null);
        $categoryId = (int)($body['categoryId'] ?? 0);
        $departmentId = (int)($body['departmentId'] ?? 0);
        if ($categoryId < 1) $categoryId = (int)$this->pdo->query('SELECT id FROM categories WHERE status = \'active\' ORDER BY id LIMIT 1')->fetchColumn();
        if ($departmentId < 1) $departmentId = (int)$this->pdo->query('SELECT id FROM departments WHERE status = \'active\' ORDER BY id LIMIT 1')->fetchColumn();
        if (!$categoryId || !$departmentId) waiaError('No hay categorías o departamentos configurados en la base de datos.', 422);
        $slug = trim(strtolower(preg_replace('/[^a-z0-9]+/i', '-', $title)), '-') . '-' . bin2hex(random_bytes(3));
        $stmt = $this->pdo->prepare('INSERT INTO experiences (title, slug, category_id, department_id, host_id, location, short_description, long_description, duration_minutes, max_participants, price_usd, price_nio, currency_primary, latitude, longitude, main_image_url, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, \'USD\', ?, ?, ?, \'published\')');
        $stmt->execute([$title, $slug, $categoryId, $departmentId, $hostId, $location, $shortDescription, trim((string)($body['description'] ?? $shortDescription)), max(0, (int)($body['durationMinutes'] ?? 0)), max(0, (int)($body['maxParticipants'] ?? 0)), max(0, (float)($body['priceUsd'] ?? 0)), max(0, (float)($body['priceNio'] ?? 0)), $latitude, $longitude, $imageUrl]);
        waiaJson(['success' => true, 'id' => (int)$this->pdo->lastInsertId(), 'imageUrl' => $imageUrl, 'latitude' => $latitude, 'longitude' => $longitude, 'message' => 'Experiencia publicada correctamente.'], 201);
    }

    private function coordinate(mixed $value, float $min, float $max): ?float
    {
        if ($value === null || $value === '') return null;
        if (!is_numeric($value) || (float)$value < $min || (float)$value > $max) waiaError('La ubicacion GPS no es valida.', 422);
        return round((float)$value, 7);
    }

    private function storeImage(?array $file): ?string
    {
        if (!$file || (int)($file['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) return null;
        if ((int)($file['error'] ?? UPLOAD_ERR_OK) !== UPLOAD_ERR_OK || (int)($file['size'] ?? 0) > 5 * 1024 * 1024) waiaError('La imagen no pudo subirse o supera 5 MB.', 422);
        $mime = (new finfo(FILEINFO_MIME_TYPE))->file((string)$file['tmp_name']);
        $extensions = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];
        if (!isset($extensions[$mime]) || @getimagesize((string)$file['tmp_name']) === false) waiaError('Formato de imagen no permitido. Usa JPG, PNG o WEBP.', 422);
        $directory = dirname(__DIR__, 2) . '/uploads/experiences';
        if (!is_dir($directory) && !mkdir($directory, 0755, true)) waiaError('No se pudo preparar el almacenamiento de imagenes.', 500);
        $filename = bin2hex(random_bytes(16)) . '.' . $extensions[$mime];
        if (!move_uploaded_file((string)$file['tmp_name'], $directory . '/' . $filename)) waiaError('No se pudo guardar la imagen.', 500);
        $script = str_replace('\\', '/', (string)($_SERVER['SCRIPT_NAME'] ?? '/backend/api/index.php'));
        return rtrim(dirname(dirname($script)), '/') . '/uploads/experiences/' . $filename;
    }
}
