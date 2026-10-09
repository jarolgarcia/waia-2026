<?php
declare(strict_types=1);

const WAIA_ACCESS_TTL = 1800;
const WAIA_REFRESH_INTERVAL = 600;
const WAIA_MAX_REFRESHES = 3;

function waiaCookieSecure(): bool
{
    return (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || getenv('SESSION_SECURE_COOKIE') === 'true';
}

function waiaStartSession(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) return;
    session_name('WAIA_SESSION');
    session_set_cookie_params(['lifetime' => 0, 'path' => '/', 'secure' => waiaCookieSecure(), 'httponly' => true, 'samesite' => 'Lax']);
    ini_set('session.use_strict_mode', '1');
    ini_set('session.use_only_cookies', '1');
    session_start();
}

function waiaSecurityHeaders(): void
{
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');
    header('Referrer-Policy: strict-origin-when-cross-origin');
    header('Permissions-Policy: geolocation=(), camera=(), microphone=()');
    header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
    if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
}

function waiaSetTokenCookie(string $name, string $value, int $maxAge): void
{
    setcookie($name, $value, ['expires' => time() + $maxAge, 'path' => '/', 'secure' => waiaCookieSecure(), 'httponly' => true, 'samesite' => 'Lax']);
}

function waiaIssueTokens(bool $resetRefreshCount = false): array
{
    waiaStartSession();
    $accessToken = bin2hex(random_bytes(32));
    $refreshToken = bin2hex(random_bytes(32));
    $_SESSION['access_token_hash'] = hash('sha256', $accessToken);
    $_SESSION['access_expires_at'] = time() + WAIA_ACCESS_TTL;
    $_SESSION['refresh_token_hash'] = hash('sha256', $refreshToken);
    $_SESSION['refresh_expires_at'] = time() + WAIA_REFRESH_INTERVAL;
    if ($resetRefreshCount) $_SESSION['refresh_count'] = 0;
    waiaSetTokenCookie('WAIA_ACCESS_TOKEN', $accessToken, WAIA_ACCESS_TTL);
    waiaSetTokenCookie('WAIA_REFRESH_TOKEN', $refreshToken, WAIA_REFRESH_INTERVAL);
    return ['expiresIn' => WAIA_ACCESS_TTL, 'refreshIn' => WAIA_REFRESH_INTERVAL, 'maxRefreshes' => WAIA_MAX_REFRESHES];
}

function waiaRefreshTokens(): array
{
    waiaStartSession();
    $refreshToken = (string)($_COOKIE['WAIA_REFRESH_TOKEN'] ?? '');
    $valid = $refreshToken !== '' && !empty($_SESSION['refresh_token_hash']) && hash_equals($_SESSION['refresh_token_hash'], hash('sha256', $refreshToken)) && time() < (int)($_SESSION['refresh_expires_at'] ?? 0);
    $count = (int)($_SESSION['refresh_count'] ?? 0);
    if (!$valid || $count >= WAIA_MAX_REFRESHES) { waiaDestroyAuthSession(); waiaError('La sesión expiró. Inicia sesión nuevamente.', 401); }
    if ($count + 1 >= WAIA_MAX_REFRESHES) { waiaDestroyAuthSession(); waiaError('La sesión alcanzó el límite de renovaciones.', 401); }
    $_SESSION['refresh_count'] = $count + 1;
    return waiaIssueTokens(false);
}

function waiaRequireAuth(): array
{
    waiaStartSession();
    $user = $_SESSION['user'] ?? null;
    $accessToken = (string)($_COOKIE['WAIA_ACCESS_TOKEN'] ?? '');
    if ($accessToken === '' && !empty($_SERVER['HTTP_AUTHORIZATION']) && preg_match('/^Bearer\s+(.+)$/i', $_SERVER['HTTP_AUTHORIZATION'], $matches)) $accessToken = $matches[1];
    $validToken = $accessToken !== '' && !empty($_SESSION['access_token_hash']) && hash_equals($_SESSION['access_token_hash'], hash('sha256', $accessToken));
    if (!is_array($user) || empty($user['id']) || !$validToken || time() >= (int)($_SESSION['access_expires_at'] ?? 0)) waiaError('La sesión expiró. Inicia sesión nuevamente.', 401);
    return $user;
}

function waiaRequireCsrf(): void
{
    waiaStartSession();
    $token = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? '';
    if (!$token || empty($_SESSION['csrf_token']) || !hash_equals($_SESSION['csrf_token'], $token)) waiaError('Token CSRF inválido o ausente.', 419);
}

function waiaCsrfToken(): string
{
    waiaStartSession();
    if (empty($_SESSION['csrf_token'])) $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    return $_SESSION['csrf_token'];
}

function waiaClearSessionCookie(): void
{
    setcookie(session_name(), '', ['expires' => time() - 3600, 'path' => '/', 'secure' => waiaCookieSecure(), 'httponly' => true, 'samesite' => 'Lax']);
}

function waiaClearTokenCookies(): void
{
    foreach (['WAIA_ACCESS_TOKEN', 'WAIA_REFRESH_TOKEN'] as $name) setcookie($name, '', ['expires' => time() - 3600, 'path' => '/', 'secure' => waiaCookieSecure(), 'httponly' => true, 'samesite' => 'Lax']);
}

function waiaDestroyAuthSession(): void
{
    waiaStartSession();
    $_SESSION = [];
    waiaClearTokenCookies();
    if (ini_get('session.use_cookies')) waiaClearSessionCookie();
    session_destroy();
}
