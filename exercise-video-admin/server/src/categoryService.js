import { config } from './config.js';
import { firestore, fv } from './firebase.js';
import { sanitizeFirestoreValue } from './serialize.js';

export const PLACEMENT_KEYS = [
  'workout_home',
  'create_workout_chip',
  'video_library_filter',
];

const col = () => firestore().collection(config.categoriesCollection);

export const DEFAULT_CATEGORIES = [
  {
    id: 'strength',
    workoutCategory: 'strength',
    sfSymbolFallback: 'dumbbell.fill',
    placements: {
      create_workout_chip: { enabled: true, label: 'Strength', sortOrder: 0 },
      video_library_filter: { enabled: true, label: 'Strength', sortOrder: 1 },
    },
  },
  {
    id: 'cardio',
    workoutCategory: 'cardio',
    sfSymbolFallback: 'figure.run',
    placements: {
      workout_home: {
        enabled: true,
        label: 'cardio',
        sortOrder: 0,
        gradient: ['#FFE4CC', '#FFCCA8'],
        exploreFilter: 'maintain',
      },
      create_workout_chip: { enabled: true, label: 'Cardio', sortOrder: 1 },
      video_library_filter: { enabled: true, label: 'Cardio', sortOrder: 2 },
    },
  },
  {
    id: 'yoga',
    workoutCategory: 'yoga',
    sfSymbolFallback: 'figure.yoga',
    placements: {
      workout_home: {
        enabled: true,
        label: 'yog',
        sortOrder: 1,
        gradient: ['#D6E8FF', '#B8D4FF'],
        exploreFilter: 'recovery',
      },
      create_workout_chip: { enabled: true, label: 'Yoga', sortOrder: 2 },
      video_library_filter: { enabled: true, label: 'Yoga', sortOrder: 3 },
    },
  },
  {
    id: 'hiit',
    workoutCategory: 'hiit',
    sfSymbolFallback: 'bolt.fill',
    placements: {
      video_library_filter: { enabled: true, label: 'HIIT', sortOrder: 4 },
    },
  },
  {
    id: 'flexibility',
    workoutCategory: 'flexibility',
    sfSymbolFallback: 'figure.strengthtraining.functional',
    placements: {
      video_library_filter: { enabled: true, label: 'Flexibility', sortOrder: 5 },
    },
  },
  {
    id: 'boxing',
    workoutCategory: null,
    sfSymbolFallback: 'figure.boxing',
    placements: {
      workout_home: {
        enabled: true,
        label: 'boxing',
        sortOrder: 2,
        gradient: ['#D4F0DD', '#A8E0B8'],
        exploreFilter: 'build',
      },
    },
  },
  {
    id: 'all',
    workoutCategory: 'all',
    sfSymbolFallback: 'square.grid.2x2',
    placements: {
      video_library_filter: { enabled: true, label: 'All', sortOrder: 0 },
    },
  },
];

export function docToCategory(id, data) {
  if (!data) return null;
  return sanitizeFirestoreValue({ id, ...data });
}

function sortCategories(list) {
  return [...list].sort((a, b) => (a.id || '').localeCompare(b.id || ''));
}

function placementEnabled(category, placement) {
  const p = category.placements && category.placements[placement];
  return !!(p && p.enabled);
}

function placementSortOrder(category, placement) {
  const p = category.placements && category.placements[placement];
  return typeof p?.sortOrder === 'number' ? p.sortOrder : 999;
}

export async function ensureSeeded() {
  const snap = await col().limit(1).get();
  if (!snap.empty) return false;

  const batch = firestore().batch();
  const now = fv().serverTimestamp();
  for (const cat of DEFAULT_CATEGORIES) {
    const { id, ...rest } = cat;
    const ref = col().doc(id);
    batch.set(ref, { ...rest, updatedAt: now }, { merge: true });
  }
  await batch.commit();
  return true;
}

/** Seed only documents that do not exist yet. */
export async function seedMissingDefaults() {
  let created = 0;
  const now = fv().serverTimestamp();
  for (const cat of DEFAULT_CATEGORIES) {
    const { id, ...rest } = cat;
    const ref = col().doc(id);
    const d = await ref.get();
    if (!d.exists) {
      await ref.set({ ...rest, updatedAt: now }, { merge: true });
      created += 1;
    }
  }
  return { created };
}

export async function listCategories({ placement } = {}) {
  await ensureSeeded();
  const snap = await col().get();
  let list = snap.docs.map((d) => docToCategory(d.id, d.data())).filter(Boolean);

  if (placement && PLACEMENT_KEYS.includes(placement)) {
    list = list.filter((c) => placementEnabled(c, placement));
    list.sort((a, b) => placementSortOrder(a, placement) - placementSortOrder(b, placement));
  } else {
    list = sortCategories(list);
  }

  return list;
}

export async function getCategory(id) {
  const d = await col().doc(id).get();
  if (!d.exists) return null;
  return docToCategory(d.id, d.data());
}

const CATEGORY_ID_RE = /^[a-z][a-z0-9_-]{0,39}$/;

export function normalizeCategoryId(raw) {
  if (raw === undefined || raw === null) return '';
  return String(raw)
    .trim()
    .toLowerCase()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_-]/g, '');
}

function validateCategoryId(id) {
  const normalized = normalizeCategoryId(id);
  if (!normalized) {
    const err = new Error('id required (lowercase letters, numbers, underscore, hyphen)');
    err.status = 400;
    throw err;
  }
  if (!CATEGORY_ID_RE.test(normalized)) {
    const err = new Error(
      'id must start with a letter and use only lowercase letters, numbers, underscore, or hyphen (max 40 chars)'
    );
    err.status = 400;
    throw err;
  }
  return normalized;
}

function sanitizePlacements(incoming) {
  if (!incoming || typeof incoming !== 'object') return {};
  const out = {};
  for (const key of PLACEMENT_KEYS) {
    if (incoming[key] === undefined || incoming[key] === null) continue;
    if (typeof incoming[key] !== 'object') continue;
    out[key] = { ...incoming[key] };
  }
  return out;
}

export async function createCategory(body) {
  const id = validateCategoryId(body && body.id);
  const ref = col().doc(id);
  const existing = await ref.get();
  if (existing.exists) {
    const err = new Error('Category already exists');
    err.status = 409;
    throw err;
  }

  const doc = {
    workoutCategory:
      body.workoutCategory === null || body.workoutCategory === '' || body.workoutCategory === undefined
        ? null
        : String(body.workoutCategory),
    sfSymbolFallback:
      body.sfSymbolFallback === null || body.sfSymbolFallback === '' || body.sfSymbolFallback === undefined
        ? 'square.grid.2x2'
        : String(body.sfSymbolFallback),
    placements: sanitizePlacements(body.placements),
    imageURL: null,
    updatedAt: fv().serverTimestamp(),
  };

  await ref.set(doc);
  const saved = await ref.get();
  return docToCategory(saved.id, saved.data());
}

function mergePlacements(existing, incoming) {
  if (!incoming || typeof incoming !== 'object') return existing || {};
  const out = { ...(existing || {}) };
  for (const key of PLACEMENT_KEYS) {
    if (incoming[key] === undefined) continue;
    const inc = incoming[key];
    if (inc === null) {
      delete out[key];
      continue;
    }
    if (typeof inc !== 'object') continue;
    out[key] = { ...(out[key] || {}), ...inc };
  }
  return out;
}

export async function patchCategory(id, body) {
  const ref = col().doc(id);
  const existing = await ref.get();
  if (!existing.exists) {
    const err = new Error('Not found');
    err.status = 404;
    throw err;
  }

  const patch = {};
  if (body.workoutCategory !== undefined) {
    patch.workoutCategory =
      body.workoutCategory === null || body.workoutCategory === ''
        ? null
        : String(body.workoutCategory);
  }
  if (body.sfSymbolFallback !== undefined) {
    patch.sfSymbolFallback =
      body.sfSymbolFallback === null ? null : String(body.sfSymbolFallback);
  }
  if (body.placements !== undefined) {
    const current = existing.data().placements || {};
    patch.placements = mergePlacements(current, body.placements);
  }
  if (body.imageURL !== undefined) {
    patch.imageURL =
      body.imageURL === null || body.imageURL === '' ? null : String(body.imageURL);
  }

  if (Object.keys(patch).length === 0) {
    const err = new Error('No valid fields');
    err.status = 400;
    throw err;
  }

  patch.updatedAt = fv().serverTimestamp();
  await ref.set(patch, { merge: true });
  const d = await ref.get();
  return docToCategory(d.id, d.data());
}

export async function setCategoryImageURL(id, url) {
  const ref = col().doc(id);
  const existing = await ref.get();
  if (!existing.exists) {
    const err = new Error('Not found');
    err.status = 404;
    throw err;
  }
  await ref.set(
    { imageURL: url, updatedAt: fv().serverTimestamp() },
    { merge: true }
  );
  const d = await ref.get();
  return docToCategory(d.id, d.data());
}
