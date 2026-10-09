<?php
declare(strict_types=1);

// Mantiene el formato JSON simple que utiliza la API de sincronización.
if (!function_exists('waiaJson')) {
    function waiaJson(mixed $data, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}

// config/config.php ya define waiaError(). Evitar declararla dos veces.
// Si se usa este helper de forma independiente, ofrece una implementación alternativa.
if (!function_exists('waiaError')) {
    function waiaError(string $message, int $status = 400, mixed $extra = null): void
    {
        $response = ['success' => false, 'error' => $message];
        if (is_array($extra)) {
            $response = array_merge($response, $extra);
        } elseif ($extra !== null) {
            $response['data'] = $extra;
        }
        waiaJson($response, $status);
    }
}
