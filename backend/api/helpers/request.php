<?php
declare(strict_types=1);

function waiaJsonBody(): array
{
    $raw = file_get_contents('php://input') ?: '';
    if ($raw === '') return [];
    $data = json_decode($raw, true);
    if (!is_array($data)) waiaError('El cuerpo JSON no es válido.', 400);
    return $data;
}

function waiaHeader(string $name, ?string $default = null): ?string
{
    $key = 'HTTP_' . strtoupper(str_replace('-', '_', $name));
    return isset($_SERVER[$key]) ? trim((string)$_SERVER[$key]) : $default;
}
