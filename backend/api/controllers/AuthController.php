<?php
declare(strict_types=1);

require_once __DIR__ . '/../helpers/request.php';
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../middleware/security.php';

final class AuthController
{
    private const LOGIN_MAX_FAILURES = 5;
    private const LOGIN_WINDOW_SECONDS = 900;
    private const LOGIN_BLOCK_SECONDS = 300;
    private static bool $rateLimitTableReady = false;

    public function __construct(private PDO $pdo) {}

    public function handle(string $action, string $method): never
    {
        if ($action === 'register' && $method === 'POST') $this->register();
        if ($action === 'login' && $method === 'POST') $this->login();
        if ($action === 'refresh' && $method === 'POST') $this->refresh();
        if ($action === 'logout' && $method === 'POST') $this->logout();
        if ($action === 'me' && $method === 'GET') $this->me();
        waiaError('Método no permitido.', 405);
    }

    private function register(): never
    {
        $body = waiaJsonBody();
        $name = trim((string)($body['name'] ?? ''));
        $email = strtolower(trim((string)($body['email'] ?? '')));
        $password = (string)($body['password'] ?? '');
        $requestedRole = trim((string)($body['role'] ?? 'turista'));
        if (mb_strlen($name) < 3 || !filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($password) < 8) {
            waiaError('Nombre, correo o contraseña inválidos.', 422);
        }

        $columns = $this->userColumns();
        $passwordColumn = in_array('password_hash', $columns, true) ? 'password_hash' : 'password';
        $role = $this->databaseRole($requestedRole);
        $hash = password_hash($password, PASSWORD_DEFAULT);
        $fields = ['email', $passwordColumn];
        $values = [$email, $hash];
        if (in_array('name', $columns, true)) { $fields[] = 'name'; $values[] = $name; }
        if (in_array('first_name', $columns, true)) {
            $parts = preg_split('/\s+/', $name, 2);
            $fields[] = 'first_name'; $values[] = $parts[0];
            if (in_array('last_name', $columns, true)) { $fields[] = 'last_name'; $values[] = $parts[1] ?? ''; }
        }
        if (in_array('role', $columns, true)) { $fields[] = 'role'; $values[] = $role; }
        if (in_array('status', $columns, true)) { $fields[] = 'status'; $values[] = 'active'; }
        $placeholders = implode(', ', array_fill(0, count($fields), '?'));
        try {
            $stmt = $this->pdo->prepare('INSERT INTO users (' . implode(', ', $fields) . ') VALUES (' . $placeholders . ')');
            $stmt->execute($values);
        } catch (PDOException $exception) {
            if ((int)$exception->errorInfo[1] === 1062) waiaError('Ese correo ya está registrado.', 409);
            throw $exception;
        }

        $id = (int)$this->pdo->lastInsertId();
        if ($role === 'host') {
            $hostStmt = $this->pdo->prepare('INSERT INTO hosts (user_id, name, email, status) VALUES (?, ?, ?, \'active\')');
            $hostStmt->execute([$id, $name, $email]);
        }
        waiaStartSession();
        session_regenerate_id(true);
        $_SESSION['user'] = ['id' => $id, 'name' => $name, 'email' => $email, 'role' => $role];
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        waiaJson(['success' => true, 'user' => $_SESSION['user'], 'csrfToken' => $_SESSION['csrf_token'], ...waiaIssueTokens(true)], 201);
    }

    private function login(): never
    {
        $body = waiaJsonBody();
        $email = strtolower(trim((string)($body['email'] ?? '')));
        $password = (string)($body['password'] ?? '');
        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($password) < 8) {
            waiaError('Correo o contraseña inválidos.', 422);
        }

        $columns = $this->userColumns();
        $passwordColumn = in_array('password_hash', $columns, true) ? 'password_hash' : 'password';
        $retryAfter = $this->loginRateLimitStatus($email);
        if ($retryAfter > 0) {
            header('Retry-After: ' . $retryAfter);
            waiaError('Demasiados intentos de inicio de sesion. Intenta nuevamente mas tarde.', 429);
        }

        $statusWhere = in_array('status', $columns, true) ? ' AND status = \'active\'' : '';
        $roleExpression = in_array('role', $columns, true) ? 'role' : "'user'";
        $nameExpression = in_array('first_name', $columns, true) ? "CONCAT(first_name, ' ', last_name)" : 'name';
        $stmt = $this->pdo->prepare("SELECT id, email, {$passwordColumn} AS password_value, {$roleExpression} AS role, {$nameExpression} AS name FROM users WHERE email = ?{$statusWhere} LIMIT 1");
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$user || !password_verify($password, (string)$user['password_value'])) {
            $this->recordLoginFailure($email);
            usleep(250000);
            waiaError('Credenciales incorrectas.', 401);
        }

        $this->clearLoginFailures($email);

        waiaStartSession();
        session_regenerate_id(true);
        $_SESSION['user'] = ['id' => (int)$user['id'], 'name' => $user['name'], 'email' => $user['email'], 'role' => $user['role']];
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        waiaJson(['success' => true, 'user' => $_SESSION['user'], 'csrfToken' => $_SESSION['csrf_token'], ...waiaIssueTokens(true)]);
    }

    private function refresh(): never
    {
        $user = waiaRequireAuth();
        waiaJson(['success' => true, 'user' => $user, ...waiaRefreshTokens(), 'csrfToken' => waiaCsrfToken()]);
    }

    private function me(): never
    {
        $user = waiaRequireAuth();
        waiaJson(['success' => true, 'user' => $user, 'csrfToken' => waiaCsrfToken()]);
    }

    private function logout(): never
    {
        waiaStartSession();
        waiaDestroyAuthSession();
        waiaJson(['success' => true]);
    }

    private function userColumns(): array
    {
        $stmt = $this->pdo->query("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'");
        return array_map('strval', $stmt->fetchAll(PDO::FETCH_COLUMN));
    }

    private function ensureLoginRateLimitTable(): void
    {
        if (self::$rateLimitTableReady) return;
        $this->pdo->exec("CREATE TABLE IF NOT EXISTS auth_login_rate_limits (
            email_hash CHAR(64) NOT NULL PRIMARY KEY,
            failure_count INT UNSIGNED NOT NULL DEFAULT 0,
            first_failure_at DATETIME NOT NULL,
            blocked_until DATETIME NULL,
            updated_at DATETIME NOT NULL,
            INDEX idx_auth_login_blocked_until (blocked_until)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
        self::$rateLimitTableReady = true;
    }

    private function loginEmailHash(string $email): string
    {
        return hash('sha256', strtolower(trim($email)));
    }

    private function loginRateLimitStatus(string $email): int
    {
        $this->ensureLoginRateLimitTable();
        $stmt = $this->pdo->prepare('SELECT blocked_until FROM auth_login_rate_limits WHERE email_hash = ? LIMIT 1');
        $stmt->execute([$this->loginEmailHash($email)]);
        $blockedUntil = $stmt->fetchColumn();
        if (!$blockedUntil) return 0;
        // Los timestamps del rate limit se guardan en UTC.
        $retryAfter = max(0, strtotime((string)$blockedUntil . ' UTC') - time());
        // Reduce bloqueos creados con la configuración anterior a la nueva ventana de 5 minutos.
        if ($retryAfter > self::LOGIN_BLOCK_SECONDS) {
            $retryAfter = self::LOGIN_BLOCK_SECONDS;
            $update = $this->pdo->prepare('UPDATE auth_login_rate_limits SET blocked_until = ? WHERE email_hash = ?');
            $update->execute([gmdate('Y-m-d H:i:s', time() + self::LOGIN_BLOCK_SECONDS), $this->loginEmailHash($email)]);
        }
        return $retryAfter;
    }

    private function recordLoginFailure(string $email): void
    {
        $this->ensureLoginRateLimitTable();
        $hash = $this->loginEmailHash($email);
        $now = gmdate('Y-m-d H:i:s');
        $this->pdo->beginTransaction();
        try {
            $stmt = $this->pdo->prepare('SELECT failure_count, first_failure_at FROM auth_login_rate_limits WHERE email_hash = ? FOR UPDATE');
            $stmt->execute([$hash]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $withinWindow = $row && (time() - (int)strtotime((string)$row['first_failure_at'] . ' UTC')) < self::LOGIN_WINDOW_SECONDS;
            $count = $withinWindow ? ((int)$row['failure_count'] + 1) : 1;
            $firstFailureAt = $withinWindow ? (string)$row['first_failure_at'] : $now;
            $blockedUntil = $count >= self::LOGIN_MAX_FAILURES ? gmdate('Y-m-d H:i:s', time() + self::LOGIN_BLOCK_SECONDS) : null;
            if ($row) {
                $update = $this->pdo->prepare('UPDATE auth_login_rate_limits SET failure_count = ?, first_failure_at = ?, blocked_until = ?, updated_at = ? WHERE email_hash = ?');
                $update->execute([$count, $firstFailureAt, $blockedUntil, $now, $hash]);
            } else {
                $insert = $this->pdo->prepare('INSERT INTO auth_login_rate_limits (email_hash, failure_count, first_failure_at, blocked_until, updated_at) VALUES (?, ?, ?, ?, ?)');
                $insert->execute([$hash, $count, $firstFailureAt, $blockedUntil, $now]);
            }
            $this->pdo->commit();
        } catch (Throwable $exception) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $exception;
        }
    }

    private function clearLoginFailures(string $email): void
    {
        $this->ensureLoginRateLimitTable();
        $stmt = $this->pdo->prepare('DELETE FROM auth_login_rate_limits WHERE email_hash = ?');
        $stmt->execute([$this->loginEmailHash($email)]);
    }

    private function databaseRole(string $requestedRole): string
    {
        $stmt = $this->pdo->query("SELECT COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'role'");
        $type = (string)$stmt->fetchColumn();
        preg_match_all("/'([^']+)'/", $type, $matches);
        $allowed = $matches[1] ?? [];
        if (in_array($requestedRole, $allowed, true)) return $requestedRole;
        if ($requestedRole === 'anfitrion' && in_array('host', $allowed, true)) return 'host';
        return in_array('turista', $allowed, true) ? 'turista' : (in_array('user', $allowed, true) ? 'user' : ($allowed[0] ?? 'user'));
    }
}
