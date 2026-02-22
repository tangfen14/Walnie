import 'dotenv/config';

import cors from 'cors';
import express from 'express';

import { config } from './config.js';
import {
  checkDatabaseConnection,
  closeDatabase,
  pool,
  runMigrations,
} from './db.js';
import {
  mysqlDateTimeToIso,
  parseIsoDate,
  parseOptionalIsoDate,
  toMysqlDateTime,
} from './time.js';

const EVENT_TYPES = new Set(['feed', 'poop', 'pee', 'diaper', 'pump']);
const FEED_METHODS = new Set([
  'breastLeft',
  'breastRight',
  'bottleFormula',
  'bottleBreastmilk',
  'mixed',
]);
const DIAPER_STATUS = new Set(['poop', 'pee', 'mixed']);
const ATTACHMENT_MIME_TYPES = new Set(['image/jpeg', 'image/png']);

function makeHttpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function parseOptionalPositiveInt(value, fieldName) {
  if (value == null || value === '') {
    return null;
  }

  if (!Number.isInteger(value) || value <= 0) {
    throw makeHttpError(400, `${fieldName} must be a positive integer`);
  }
  return value;
}

function parseOptionalNonNegativeInt(value, fieldName) {
  if (value == null || value === '') {
    return null;
  }

  if (!Number.isInteger(value) || value < 0) {
    throw makeHttpError(400, `${fieldName} must be a non-negative integer`);
  }
  return value;
}

function parseOptionalString(value, fieldName) {
  if (value == null || value === '') {
    return null;
  }

  if (typeof value !== 'string') {
    throw makeHttpError(400, `${fieldName} must be a string`);
  }

  return value;
}

function parseOptionalBool(value, fieldName) {
  if (value == null) {
    return null;
  }

  if (typeof value !== 'boolean') {
    throw makeHttpError(400, `${fieldName} must be a boolean`);
  }

  return value;
}

function parseEventType(value) {
  if (typeof value !== 'string' || !EVENT_TYPES.has(value)) {
    throw makeHttpError(400, 'type is invalid');
  }
  return value;
}

function parseOptionalFeedMethod(value) {
  if (value == null || value === '') {
    return null;
  }

  if (typeof value !== 'string' || !FEED_METHODS.has(value)) {
    throw makeHttpError(400, 'feedMethod is invalid');
  }

  return value;
}

function normalizeAttachment(raw, index) {
  if (raw == null || typeof raw !== 'object' || Array.isArray(raw)) {
    throw makeHttpError(400, `eventMeta.attachments[${index}] must be an object`);
  }

  const id = parseOptionalString(raw.id, `eventMeta.attachments[${index}].id`);
  const mimeType = parseOptionalString(
    raw.mimeType,
    `eventMeta.attachments[${index}].mimeType`,
  );
  const base64 = parseOptionalString(
    raw.base64,
    `eventMeta.attachments[${index}].base64`,
  );
  const createdAtRaw = parseOptionalString(
    raw.createdAt,
    `eventMeta.attachments[${index}].createdAt`,
  );

  if (id == null || id.trim() === '') {
    throw makeHttpError(400, `eventMeta.attachments[${index}].id is required`);
  }
  if (mimeType == null || !ATTACHMENT_MIME_TYPES.has(mimeType)) {
    throw makeHttpError(
      400,
      `eventMeta.attachments[${index}].mimeType must be image/jpeg or image/png`,
    );
  }
  if (base64 == null || base64.trim() === '') {
    throw makeHttpError(400, `eventMeta.attachments[${index}].base64 is required`);
  }
  if (createdAtRaw == null) {
    throw makeHttpError(
      400,
      `eventMeta.attachments[${index}].createdAt is required`,
    );
  }

  try {
    parseIsoDate(createdAtRaw, `eventMeta.attachments[${index}].createdAt`);
  } catch (error) {
    throw makeHttpError(400, error.message);
  }

  return {
    id,
    mimeType,
    base64,
    createdAt: createdAtRaw,
  };
}

function parseEventMeta(rawEventMeta, type) {
  const isDiaperLike = type === 'diaper' || type === 'poop' || type === 'pee';
  if (rawEventMeta == null) {
    if (!isDiaperLike) {
      return null;
    }
    const status = type === 'poop' ? 'poop' : (type === 'pee' ? 'pee' : 'mixed');
    return {
      schemaVersion: 1,
      status,
      changedDiaper: true,
      hasRash: false,
      attachments: [],
    };
  }

  if (
    rawEventMeta == null ||
    typeof rawEventMeta !== 'object' ||
    Array.isArray(rawEventMeta)
  ) {
    throw makeHttpError(400, 'eventMeta must be an object');
  }

  const schemaVersionRaw = rawEventMeta.schemaVersion;
  const schemaVersion = schemaVersionRaw == null ? 1 : schemaVersionRaw;
  if (!Number.isInteger(schemaVersion) || schemaVersion <= 0) {
    throw makeHttpError(400, 'eventMeta.schemaVersion must be a positive integer');
  }

  const statusRaw = parseOptionalString(rawEventMeta.status, 'eventMeta.status');
  const changedDiaper = parseOptionalBool(
    rawEventMeta.changedDiaper,
    'eventMeta.changedDiaper',
  );
  const hasRash = parseOptionalBool(rawEventMeta.hasRash, 'eventMeta.hasRash');
  const feedLeftDurationMin = parseOptionalNonNegativeInt(
    rawEventMeta.feedLeftDurationMin,
    'eventMeta.feedLeftDurationMin',
  );
  const feedRightDurationMin = parseOptionalNonNegativeInt(
    rawEventMeta.feedRightDurationMin,
    'eventMeta.feedRightDurationMin',
  );
  const pumpLeftMl = parseOptionalNonNegativeInt(
    rawEventMeta.pumpLeftMl,
    'eventMeta.pumpLeftMl',
  );
  const pumpRightMl = parseOptionalNonNegativeInt(
    rawEventMeta.pumpRightMl,
    'eventMeta.pumpRightMl',
  );

  if (isDiaperLike && statusRaw == null) {
    throw makeHttpError(400, 'eventMeta.status is required for diaper-like events');
  }

  if (isDiaperLike && changedDiaper == null) {
    throw makeHttpError(400, 'eventMeta.changedDiaper is required for diaper-like events');
  }

  if (statusRaw != null && !DIAPER_STATUS.has(statusRaw)) {
    throw makeHttpError(400, 'eventMeta.status is invalid');
  }

  if (type !== 'diaper' && hasRash != null) {
    throw makeHttpError(400, 'eventMeta.hasRash is only allowed for diaper events');
  }
  if (type !== 'feed' && (feedLeftDurationMin != null || feedRightDurationMin != null)) {
    throw makeHttpError(
      400,
      'eventMeta.feedLeftDurationMin and eventMeta.feedRightDurationMin are only allowed for feed events',
    );
  }
  if (type !== 'pump' && (pumpLeftMl != null || pumpRightMl != null)) {
    throw makeHttpError(
      400,
      'eventMeta.pumpLeftMl and eventMeta.pumpRightMl are only allowed for pump events',
    );
  }

  const attachmentsRaw = rawEventMeta.attachments;
  if (attachmentsRaw != null && !Array.isArray(attachmentsRaw)) {
    throw makeHttpError(400, 'eventMeta.attachments must be an array');
  }

  const attachments = (attachmentsRaw ?? []).map((item, index) =>
    normalizeAttachment(item, index),
  );

  if (attachments.length > 3) {
    throw makeHttpError(400, 'eventMeta.attachments cannot exceed 3 items');
  }

  return {
    schemaVersion,
    status: statusRaw,
    changedDiaper,
    hasRash,
    feedLeftDurationMin,
    feedRightDurationMin,
    pumpLeftMl,
    pumpRightMl,
    attachments,
  };
}

function normalizeEventPayload(body) {
  if (body == null || typeof body !== 'object') {
    throw makeHttpError(400, 'request body must be a JSON object');
  }

  const id = parseOptionalString(body.id, 'id');
  if (id == null) {
    throw makeHttpError(400, 'id is required');
  }

  const sourceType = parseEventType(body.type);
  const type = sourceType === 'poop' || sourceType === 'pee' ? 'diaper' : sourceType;

  let occurredAt;
  let createdAt;
  let updatedAt;
  let pumpStartAt;
  let pumpEndAt;

  try {
    occurredAt = parseIsoDate(body.occurredAt, 'occurredAt');
    createdAt = parseIsoDate(body.createdAt, 'createdAt');
    updatedAt = parseIsoDate(body.updatedAt, 'updatedAt');
    pumpStartAt = parseOptionalIsoDate(body.pumpStartAt, 'pumpStartAt');
    pumpEndAt = parseOptionalIsoDate(body.pumpEndAt, 'pumpEndAt');
  } catch (error) {
    throw makeHttpError(400, error.message);
  }

  const durationMin = parseOptionalNonNegativeInt(body.durationMin, 'durationMin');
  const amountMl = parseOptionalPositiveInt(body.amountMl, 'amountMl');
  const note = parseOptionalString(body.note, 'note');
  const feedMethod = parseOptionalFeedMethod(body.feedMethod);
  const eventMeta = parseEventMeta(body.eventMeta, sourceType);

  if (
    type === 'pump' &&
    eventMeta != null &&
    (eventMeta.pumpLeftMl != null || eventMeta.pumpRightMl != null)
  ) {
    const sideTotal = (eventMeta.pumpLeftMl ?? 0) + (eventMeta.pumpRightMl ?? 0);
    if (sideTotal <= 0) {
      throw makeHttpError(
        400,
        'eventMeta.pumpLeftMl + eventMeta.pumpRightMl must be greater than 0',
      );
    }
    if (amountMl == null || amountMl !== sideTotal) {
      throw makeHttpError(
        400,
        'amountMl must equal eventMeta.pumpLeftMl + eventMeta.pumpRightMl',
      );
    }
  }

  return {
    id,
    type,
    occurredAt,
    feedMethod,
    durationMin,
    amountMl,
    pumpStartAt,
    pumpEndAt,
    note,
    eventMeta,
    createdAt,
    updatedAt,
  };
}

function rowToEvent(row) {
  const normalizedType = row.type === 'poop' || row.type === 'pee' ? 'diaper' : row.type;
  let eventMeta = null;
  if (typeof row.event_meta === 'string' && row.event_meta.trim() !== '') {
    try {
      const decoded = JSON.parse(row.event_meta);
      if (decoded != null && typeof decoded === 'object' && !Array.isArray(decoded)) {
        eventMeta = decoded;
      }
    } catch {
      eventMeta = null;
    }
  }

  if (normalizedType === 'diaper') {
    eventMeta ??= {
      schemaVersion: 1,
      status: row.type === 'poop' ? 'poop' : (row.type === 'pee' ? 'pee' : 'mixed'),
      changedDiaper: true,
      hasRash: false,
      attachments: [],
    };
    eventMeta.changedDiaper ??= true;
    eventMeta.status ??= row.type === 'poop' ? 'poop' : (row.type === 'pee' ? 'pee' : 'mixed');
  }

  return {
    id: row.id,
    type: normalizedType,
    occurredAt: mysqlDateTimeToIso(row.occurred_at),
    feedMethod: row.feed_method,
    durationMin: row.duration_min,
    amountMl: row.amount_ml,
    pumpStartAt: mysqlDateTimeToIso(row.pump_start_at),
    pumpEndAt: mysqlDateTimeToIso(row.pump_end_at),
    note: row.note,
    eventMeta,
    createdAt: mysqlDateTimeToIso(row.created_at),
    updatedAt: mysqlDateTimeToIso(row.updated_at),
  };
}

function asyncRoute(handler) {
  return (req, res, next) => {
    Promise.resolve(handler(req, res, next)).catch(next);
  };
}

const app = express();
app.use(cors());
app.use(express.json({ limit: '5mb' }));

app.get(
  '/health',
  asyncRoute(async (_req, res) => {
    await checkDatabaseConnection();
    res.json({ status: 'ok', now: new Date().toISOString() });
  }),
);

app.post(
  '/v1/events',
  asyncRoute(async (req, res) => {
    const event = normalizeEventPayload(req.body);

    await pool.execute(
      `
      INSERT INTO events (
        id, type, occurred_at, feed_method, duration_min, amount_ml,
        pump_start_at, pump_end_at, note, event_meta, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        type = VALUES(type),
        occurred_at = VALUES(occurred_at),
        feed_method = VALUES(feed_method),
        duration_min = VALUES(duration_min),
        amount_ml = VALUES(amount_ml),
        pump_start_at = VALUES(pump_start_at),
        pump_end_at = VALUES(pump_end_at),
        note = VALUES(note),
        event_meta = VALUES(event_meta),
        created_at = VALUES(created_at),
        updated_at = VALUES(updated_at)
    `,
      [
        event.id,
        event.type,
        toMysqlDateTime(event.occurredAt),
        event.feedMethod,
        event.durationMin,
        event.amountMl,
        event.pumpStartAt == null ? null : toMysqlDateTime(event.pumpStartAt),
        event.pumpEndAt == null ? null : toMysqlDateTime(event.pumpEndAt),
        event.note,
        event.eventMeta == null ? null : JSON.stringify(event.eventMeta),
        toMysqlDateTime(event.createdAt),
        toMysqlDateTime(event.updatedAt),
      ],
    );

    res.status(201).json({ id: event.id });
  }),
);

app.get(
  '/v1/events',
  asyncRoute(async (req, res) => {
    let fromDate;
    let toDate;

    try {
      fromDate = parseIsoDate(req.query.from, 'from');
      toDate = parseIsoDate(req.query.to, 'to');
    } catch (error) {
      throw makeHttpError(400, error.message);
    }

    const [rows] = await pool.execute(
      `
      SELECT id, type, occurred_at, feed_method, duration_min, amount_ml,
             pump_start_at, pump_end_at, note, event_meta, created_at, updated_at
      FROM events
      WHERE occurred_at >= ? AND occurred_at < ?
      ORDER BY occurred_at DESC
    `,
      [toMysqlDateTime(fromDate), toMysqlDateTime(toDate)],
    );

    res.json(rows.map(rowToEvent));
  }),
);

app.delete(
  '/v1/events/:id',
  asyncRoute(async (req, res) => {
    const id = parseOptionalString(req.params.id, 'id');
    if (id == null) {
      throw makeHttpError(400, 'id is required');
    }

    const [result] = await pool.execute('DELETE FROM events WHERE id = ?', [
      id,
    ]);

    if (result.affectedRows === 0) {
      res.status(404).json({ message: 'not found' });
      return;
    }

    res.status(204).end();
  }),
);

app.get(
  '/v1/events/latest',
  asyncRoute(async (req, res) => {
    const type = parseEventType(req.query.type);

    const [rows] = await pool.execute(
      `
      SELECT id, type, occurred_at, feed_method, duration_min, amount_ml,
             pump_start_at, pump_end_at, note, event_meta, created_at, updated_at
      FROM events
      WHERE type = ?
      ORDER BY occurred_at DESC
      LIMIT 1
    `,
      [type],
    );

    if (rows.length === 0) {
      res.status(404).json({ message: 'not found' });
      return;
    }

    res.json(rowToEvent(rows[0]));
  }),
);

app.get(
  '/v1/summary/today',
  asyncRoute(async (_req, res) => {
    const now = new Date();
    const dayStart = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );
    const dayEnd = new Date(dayStart.getTime() + 24 * 60 * 60 * 1000);

    const [countRows] = await pool.execute(
      `
      SELECT type, COUNT(*) AS count
      FROM events
      WHERE occurred_at >= ? AND occurred_at < ?
      GROUP BY type
    `,
      [toMysqlDateTime(dayStart), toMysqlDateTime(dayEnd)],
    );

    const [latestFeedRows] = await pool.execute(
      `
      SELECT occurred_at
      FROM events
      WHERE type = 'feed' AND occurred_at >= ? AND occurred_at < ?
      ORDER BY occurred_at DESC
      LIMIT 1
    `,
      [toMysqlDateTime(dayStart), toMysqlDateTime(dayEnd)],
    );

    const summary = {
      feedCount: 0,
      poopCount: 0,
      peeCount: 0,
      diaperCount: 0,
      pumpCount: 0,
      latestFeedAt: null,
    };

    for (const row of countRows) {
      const count = Number.parseInt(row.count, 10) || 0;
      if (row.type === 'feed') summary.feedCount = count;
      if (row.type === 'poop') summary.poopCount = count;
      if (row.type === 'pee') summary.peeCount = count;
      if (row.type === 'diaper') summary.diaperCount = count;
      if (row.type === 'pump') summary.pumpCount = count;
    }

    if (latestFeedRows.length > 0) {
      summary.latestFeedAt = mysqlDateTimeToIso(latestFeedRows[0].occurred_at);
    }

    res.json(summary);
  }),
);

app.get(
  '/v1/reminder-policy',
  asyncRoute(async (_req, res) => {
    const [rows] = await pool.execute(
      'SELECT interval_hours FROM reminder_policy WHERE id = 1 LIMIT 1',
    );

    if (rows.length === 0) {
      res.json({ intervalHours: 3 });
      return;
    }

    res.json({ intervalHours: rows[0].interval_hours });
  }),
);

app.post(
  '/v1/reminder-policy',
  asyncRoute(async (req, res) => {
    const intervalHours = req.body?.intervalHours;
    if (!Number.isInteger(intervalHours) || intervalHours < 1 || intervalHours > 6) {
      throw makeHttpError(400, 'intervalHours must be an integer in range 1-6');
    }

    const now = new Date();
    await pool.execute(
      `
      INSERT INTO reminder_policy (id, interval_hours, updated_at)
      VALUES (1, ?, ?)
      ON DUPLICATE KEY UPDATE
        interval_hours = VALUES(interval_hours),
        updated_at = VALUES(updated_at)
    `,
      [intervalHours, toMysqlDateTime(now)],
    );

    res.json({ intervalHours });
  }),
);

app.use((error, _req, res, _next) => {
  const statusCode = error.statusCode ?? 500;
  const message = statusCode >= 500 ? 'internal server error' : error.message;
  if (statusCode >= 500) {
    console.error(error);
  }
  res.status(statusCode).json({ message });
});

let server;

async function start() {
  await runMigrations();
  await checkDatabaseConnection();

  server = app.listen(config.port, () => {
    console.log(`Walnie API listening on :${config.port}`);
  });
}

async function shutdown(signal) {
  console.log(`${signal} received, shutting down...`);
  if (server != null) {
    await new Promise((resolve) => server.close(resolve));
  }
  await closeDatabase();
  process.exit(0);
}

process.on('SIGINT', () => {
  shutdown('SIGINT').catch((error) => {
    console.error(error);
    process.exit(1);
  });
});

process.on('SIGTERM', () => {
  shutdown('SIGTERM').catch((error) => {
    console.error(error);
    process.exit(1);
  });
});

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
