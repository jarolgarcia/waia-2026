USE waia;

CREATE TABLE IF NOT EXISTS sync_records (
    id CHAR(36) NOT NULL,
    scope_key VARCHAR(190) NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    entity VARCHAR(80) NOT NULL,
    record_id VARCHAR(190) NOT NULL,
    action ENUM('create','update','upsert','delete') NOT NULL DEFAULT 'upsert',
    version BIGINT UNSIGNED NOT NULL DEFAULT 1,
    payload JSON NOT NULL,
    checksum CHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_sync_scope_entity_record (scope_key, entity, record_id),
    KEY idx_sync_scope_version (scope_key, version),
    KEY idx_sync_device (device_id),
    KEY idx_sync_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
