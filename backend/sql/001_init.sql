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
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  INDEX idx_events_occurred_at (occurred_at),
  INDEX idx_events_type_occurred_at (type, occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reminder_policy (
  id TINYINT NOT NULL,
  interval_hours TINYINT NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
