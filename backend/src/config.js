function parseIntEnv(name, defaultValue) {
  const raw = process.env[name];
  if (raw == null || raw.trim() == '') {
    return defaultValue;
  }

  const parsed = Number.parseInt(raw, 10);
  if (Number.isNaN(parsed)) {
    throw new Error(`${name} must be an integer`);
  }
  return parsed;
}

export const config = {
  port: parseIntEnv('PORT', 8080),
  db: {
    host: process.env.DB_HOST ?? '127.0.0.1',
    port: parseIntEnv('DB_PORT', 3306),
    user: process.env.DB_USER ?? 'walnie',
    password: process.env.DB_PASSWORD ?? '',
    database: process.env.DB_NAME ?? 'walnie',
    connectionLimit: parseIntEnv('DB_POOL_LIMIT', 10),
  },
};
