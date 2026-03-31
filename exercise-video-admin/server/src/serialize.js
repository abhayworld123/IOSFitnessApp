/**
 * Convert Firestore field values to JSON-safe primitives so res.json() never fails
 * (e.g. Timestamp, GeoPoint, DocumentReference, BigInt).
 */
export function sanitizeFirestoreValue(v) {
  if (v === null || v === undefined) return v;
  if (typeof v === 'bigint') return v.toString();
  if (typeof v === 'number' && (Number.isNaN(v) || !Number.isFinite(v))) return null;

  if (typeof v === 'object' && v !== null && typeof v.toDate === 'function') {
    try {
      return v.toDate().toISOString();
    } catch {
      return null;
    }
  }
  if (v instanceof Date) return v.toISOString();

  if (Array.isArray(v)) return v.map(sanitizeFirestoreValue);

  if (typeof v === 'object' && v !== null) {
    const ctor = v.constructor && v.constructor.name;
    if (ctor === 'DocumentReference' && typeof v.path === 'string') {
      return v.path;
    }
    if (ctor === 'GeoPoint') {
      return { latitude: v.latitude, longitude: v.longitude };
    }

    const out = {};
    for (const [k, val] of Object.entries(v)) {
      if (k.startsWith('_')) continue;
      try {
        out[k] = sanitizeFirestoreValue(val);
      } catch {
        out[k] = String(val);
      }
    }
    return out;
  }

  return v;
}

export function docToExercise(id, data) {
  if (!data) return null;
  return sanitizeFirestoreValue({ id, ...data });
}
