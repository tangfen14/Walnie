import fs from 'node:fs/promises';
import path from 'node:path';

import mysql from 'mysql2/promise';

import { config } from './config.js';

export const pool = mysql.createPool({
  host: config.db.host,
  port: config.db.port,
  user: config.db.user,
  password: config.db.password,
  database: config.db.database,
  connectionLimit: config.db.connectionLimit,
  waitForConnections: true,
  queueLimit: 0,
  timezone: 'Z',
  dateStrings: true,
  charset: 'utf8mb4',
  multipleStatements: true,
});

export async function runMigrations() {
  const migrationPath = path.resolve(process.cwd(), 'sql/001_init.sql');
  const migrationSql = await fs.readFile(migrationPath, 'utf8');
  await pool.query(migrationSql);
}

export async function checkDatabaseConnection() {
  await pool.query('SELECT 1');
}

export async function closeDatabase() {
  await pool.end();
}
