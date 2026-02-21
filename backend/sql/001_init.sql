CREATE TABLE IF NOT EXISTS events (
  id VARCHAR(64) NOT NULL,
  type VARCHAR(16) NOT NULL,
  occurred_at DATETIME(3) NOT NULL,
  feed_method VARCHAR(32) NULL,
  duration_min INT NULL,
  amount_ml INT NULL,
  pump_start_at DATETIME(3) NULL,
  pump_end_at DATETIME(3) NULL,
  note TEXT NULL,
  event_meta MEDIUMTEXT NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  INDEX idx_events_occurred_at (occurred_at),
  INDEX idx_events_type_occurred_at (type, occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @event_meta_exists = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'events'
    AND COLUMN_NAME = 'event_meta'
);
SET @event_meta_ddl = IF(
  @event_meta_exists = 0,
  'ALTER TABLE events ADD COLUMN event_meta MEDIUMTEXT NULL AFTER note',
  'SELECT 1'
);
PREPARE stmt_event_meta FROM @event_meta_ddl;
EXECUTE stmt_event_meta;
DEALLOCATE PREPARE stmt_event_meta;

UPDATE events
SET type = 'diaper',
    event_meta = '{"schemaVersion":1,"status":"poop","changedDiaper":true,"attachments":[]}'
WHERE type = 'poop';

UPDATE events
SET type = 'diaper',
    event_meta = '{"schemaVersion":1,"status":"pee","changedDiaper":true,"attachments":[]}'
WHERE type = 'pee';

UPDATE events
SET event_meta = '{"schemaVersion":1,"status":"mixed","changedDiaper":true,"hasRash":false,"attachments":[]}'
WHERE type = 'diaper' AND (event_meta IS NULL OR TRIM(event_meta) = '');

CREATE TABLE IF NOT EXISTS reminder_policy (
  id TINYINT NOT NULL,
  interval_hours TINYINT NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
