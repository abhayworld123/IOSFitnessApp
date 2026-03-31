const base = () => {
  const u = (import.meta.env.VITE_API_URL || '').trim();
  if (u) return u.replace(/\/$/, '');
  if (import.meta.env.DEV) return '';
  return '';
};

function requireBaseUrl() {
  const b = base();
  if (import.meta.env.DEV && b === '') return '';
  if (!b) {
    throw new Error(
      'Missing VITE_API_URL. For local dev you can omit it if the Vite proxy is used (npm run dev) and the API runs on port 8787. Otherwise set web/.env to VITE_API_URL=http://localhost:8787 and restart Vite.'
    );
  }
  return b;
}

async function parseJsonResponse(r) {
  const text = await r.text();

  if (!r.ok) {
    if (!text.trim()) {
      throw new Error(
        `HTTP ${r.status} ${r.statusText || ''} (empty body). If using the Vite dev server, ensure the API is running on port 8787 and restart npm run dev after vite.config proxy changes.`
      );
    }
    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch {
      const snippet = text.slice(0, 200).replace(/\s+/g, ' ').trim();
      throw new Error(
        `API returned HTTP ${r.status} with non-JSON body${snippet ? `: ${snippet}` : ''}`
      );
    }
    const msg =
      parsed && typeof parsed.error === 'string'
        ? parsed.error
        : typeof parsed?.message === 'string'
          ? parsed.message
          : text.slice(0, 300);
    throw new Error(msg || `HTTP ${r.status}`);
  }

  if (!text.trim()) {
    throw new Error(
      'Empty response from server. Start the API (cd server && npm run dev), confirm http://localhost:8787/health. If using a custom API URL, set VITE_API_URL in web/.env and restart Vite.'
    );
  }

  try {
    return JSON.parse(text);
  } catch (e) {
    const hint = text.trimStart().startsWith('<')
      ? ' Received HTML — wrong URL or SPA fallback.'
      : '';
    throw new Error(`Invalid JSON from API${hint} (${e.message})`);
  }
}

export function getStoredKey() {
  return sessionStorage.getItem('adminApiKey') || '';
}

export function setStoredKey(k) {
  sessionStorage.setItem('adminApiKey', k);
}

function headers() {
  const h = { 'Content-Type': 'application/json' };
  const k = getStoredKey();
  if (k) h.Authorization = `Bearer ${k}`;
  return h;
}

function apiUrl(path) {
  const b = requireBaseUrl();
  const p = path.startsWith('/') ? path : `/${path}`;
  return `${b}${p}`;
}

export async function listExercises() {
  const r = await fetch(apiUrl('/api/admin/exercises'), { headers: headers() });
  const j = await parseJsonResponse(r);
  return j.exercises || [];
}

export async function patchExercise(id, body) {
  const r = await fetch(apiUrl(`/api/admin/exercises/${encodeURIComponent(id)}`), {
    method: 'PATCH',
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJsonResponse(r);
}

export async function presign(id, filename, contentType) {
  const r = await fetch(apiUrl(`/api/admin/exercises/${encodeURIComponent(id)}/presign`), {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ filename, contentType }),
  });
  return parseJsonResponse(r);
}

export async function completeUpload(id, key) {
  const r = await fetch(apiUrl(`/api/admin/exercises/${encodeURIComponent(id)}/video/complete`), {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ key }),
  });
  return parseJsonResponse(r);
}

export async function presignThumbnail(id, filename, contentType) {
  const r = await fetch(apiUrl(`/api/admin/exercises/${encodeURIComponent(id)}/thumbnail/presign`), {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ filename, contentType }),
  });
  return parseJsonResponse(r);
}

export async function completeThumbnailUpload(id, key) {
  const r = await fetch(apiUrl(`/api/admin/exercises/${encodeURIComponent(id)}/thumbnail/complete`), {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ key }),
  });
  return parseJsonResponse(r);
}

/** Server fetches HTTPS URL and streams to R2; returns { animationURL, exercise }. */
export async function importVideoFromUrl(id, url) {
  const r = await fetch(apiUrl(`/api/admin/exercises/${encodeURIComponent(id)}/video/import-url`), {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ url }),
  });
  return parseJsonResponse(r);
}

/** Server fetches HTTPS URL and streams to R2; returns { thumbnailURL, exercise }. */
export async function importThumbnailFromUrl(id, url) {
  const r = await fetch(apiUrl(`/api/admin/exercises/${encodeURIComponent(id)}/thumbnail/import-url`), {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ url }),
  });
  return parseJsonResponse(r);
}

export async function uploadFileToR2(file, presignPayload) {
  const put = await fetch(presignPayload.uploadUrl, {
    method: 'PUT',
    headers: presignPayload.headers || { 'Content-Type': file.type || 'application/octet-stream' },
    body: file,
  });
  if (!put.ok) throw new Error(`R2 upload failed: ${put.status}`);
}
