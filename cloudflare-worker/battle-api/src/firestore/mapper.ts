// ---------------------------------------------------------------------------
// Firestore REST API JSON Mapper
//
// Converts plain JavaScript objects to Firestore's strictly typed REST
// JSON schema, and vice versa.
//
// Also provides a `serverTimestamp()` marker that extracts field transforms
// for the REST commit payload.
// ---------------------------------------------------------------------------

export const SERVER_TIMESTAMP_MARKER = '__isServerTimestamp';

export function serverTimestamp() {
  return { [SERVER_TIMESTAMP_MARKER]: true };
}

export interface EncodeResult {
  /** The mapped Firestore document fields. */
  fields: Record<string, any>;
  /** Any field transforms (like serverTimestamp) found during mapping. */
  transforms: any[];
}

/**
 * Encodes a top-level JS object into Firestore document fields and extracts
 * any field transforms.
 */
export function encodeDocument(data: Record<string, any>): EncodeResult {
  const fields: Record<string, any> = {};
  const transforms: any[] = [];

  for (const [key, value] of Object.entries(data)) {
    const encoded = encodeValue(value, key, transforms);
    if (encoded !== undefined) {
      fields[key] = encoded;
    }
  }

  return { fields, transforms };
}

function encodeValue(val: any, path: string, transforms: any[]): any {
  if (val === null) return { nullValue: null };
  
  if (typeof val === 'boolean') return { booleanValue: val };
  
  if (typeof val === 'number') {
    return Number.isInteger(val)
      ? { integerValue: val.toString() }
      : { doubleValue: val };
  }
  
  if (typeof val === 'string') return { stringValue: val };
  
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  
  if (typeof val === 'object') {
    if (val[SERVER_TIMESTAMP_MARKER] === true) {
      transforms.push({
        fieldPath: path,
        setToServerValue: 'REQUEST_TIME',
      });
      return undefined;
    }

    if (Array.isArray(val)) {
      const values = val
        .map((v, i) => encodeValue(v, `${path}[${i}]`, transforms))
        .filter((v) => v !== undefined);
      return { arrayValue: { values } };
    }

    const fields: Record<string, any> = {};
    for (const [k, v] of Object.entries(val)) {
      // Escape backticks in paths if needed, but for simplicity we assume standard alphanumeric keys
      const childPath = path ? `${path}.${k}` : k;
      const encoded = encodeValue(v, childPath, transforms);
      if (encoded !== undefined) {
        fields[k] = encoded;
      }
    }
    return { mapValue: { fields } };
  }

  return undefined;
}

/**
 * Decodes Firestore document fields back to a plain JS object.
 */
export function decodeDocument(fields: Record<string, any> | undefined): Record<string, any> {
  if (!fields) return {};
  const result: Record<string, any> = {};
  for (const [key, value] of Object.entries(fields)) {
    result[key] = decodeValue(value);
  }
  return result;
}

function decodeValue(val: any): any {
  if (!val) return null;
  if ('nullValue' in val) return null;
  if ('booleanValue' in val) return val.booleanValue;
  if ('integerValue' in val) return parseInt(val.integerValue, 10);
  if ('doubleValue' in val) return val.doubleValue;
  if ('stringValue' in val) return val.stringValue;
  if ('timestampValue' in val) return new Date(val.timestampValue);
  
  if ('arrayValue' in val) {
    return (val.arrayValue.values || []).map(decodeValue);
  }
  
  if ('mapValue' in val) {
    return decodeDocument(val.mapValue.fields);
  }
  
  return null;
}
