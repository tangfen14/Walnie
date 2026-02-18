function padLeft(value, width = 2) {
  return String(value).padStart(width, '0');
}

export function parseIsoDate(value, fieldName) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error(`${fieldName} is required and must be an ISO datetime string`);
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new Error(`${fieldName} must be a valid ISO datetime string`);
  }

  return date;
}

export function parseOptionalIsoDate(value, fieldName) {
  if (value == null || value === '') {
    return null;
  }

  if (typeof value !== 'string') {
    throw new Error(`${fieldName} must be a valid ISO datetime string`);
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new Error(`${fieldName} must be a valid ISO datetime string`);
  }

  return date;
}

export function toMysqlDateTime(date) {
  return (
    `${date.getUTCFullYear()}-${padLeft(date.getUTCMonth() + 1)}-${padLeft(date.getUTCDate())}` +
    ` ${padLeft(date.getUTCHours())}:${padLeft(date.getUTCMinutes())}:${padLeft(date.getUTCSeconds())}` +
    `.${padLeft(date.getUTCMilliseconds(), 3)}`
  );
}

export function mysqlDateTimeToIso(value) {
  if (value == null) {
    return null;
  }

  if (typeof value === 'string') {
    const withMs = value.includes('.') ? value : `${value}.000`;
    return `${withMs.replace(' ', 'T')}Z`;
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  throw new Error('Unsupported datetime type from database');
}
