import { Router } from 'express';
import { config } from '../config.js';
import { firestore, fv } from '../firebase.js';
import {
  assertObjectExists,
  buildObjectKey,
  buildThumbnailObjectKey,
  buildCategoryImageObjectKey,
  guessContentType,
  presignPut,
  publicUrlForKey,
} from '../r2.js';
import { parseHttpsUrl, fetchUrlToR2 } from '../importUrl.js';
import { docToExercise } from '../serialize.js';
import {
  readAiCoachSettingsFromFirestore,
  patchAiCoachSettings,
} from '../aiCoachService.js';
import {
  listCategories,
  getCategory,
  createCategory,
  patchCategory,
  seedMissingDefaults,
  setCategoryImageURL,
} from '../categoryService.js';

const router = Router();
const col = () => firestore().collection(config.exercisesCollection);

router.get('/settings/ai-coach', async (_req, res) => {
  try {
    const merged = await readAiCoachSettingsFromFirestore();
    res.json({
      settings: merged,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Load failed' });
  }
});

router.patch('/settings/ai-coach', async (req, res) => {
  try {
    const body = (req.body && typeof req.body === 'object') ? req.body : {};
    const merged = await patchAiCoachSettings(body);
    res.json({ settings: merged });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Save failed' });
  }
});

// --- Categories (workout home cards, activity chips, video library filters)

router.get('/categories', async (req, res) => {
  try {
    const placement = typeof req.query.placement === 'string' ? req.query.placement : undefined;
    const categories = await listCategories({ placement });
    res.json({ categories });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'List failed' });
  }
});

router.post('/categories', async (req, res) => {
  try {
    const body = (req.body && typeof req.body === 'object') ? req.body : {};
    const category = await createCategory(body);
    res.status(201).json(category);
  } catch (e) {
    console.error(e);
    const status = e.status || 500;
    res.status(status).json({ error: e.message || 'Create failed' });
  }
});

router.post('/categories/seed', async (_req, res) => {
  try {
    const result = await seedMissingDefaults();
    const categories = await listCategories();
    res.json({ ...result, categories });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Seed failed' });
  }
});

router.get('/categories/:id', async (req, res) => {
  try {
    const cat = await getCategory(req.params.id);
    if (!cat) return res.status(404).json({ error: 'Not found' });
    res.json(cat);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Get failed' });
  }
});

router.patch('/categories/:id', async (req, res) => {
  try {
    const body = (req.body && typeof req.body === 'object') ? req.body : {};
    const updated = await patchCategory(req.params.id, body);
    res.json(updated);
  } catch (e) {
    console.error(e);
    const status = e.status || 500;
    res.status(status).json({ error: e.message || 'Patch failed' });
  }
});

router.post('/categories/:id/image/presign', async (req, res) => {
  try {
    const { id } = req.params;
    const cat = await getCategory(id);
    if (!cat) return res.status(404).json({ error: 'Not found' });
    const filename = (req.body && req.body.filename) || 'image.png';
    const contentType = (req.body && req.body.contentType) || guessContentType(filename);
    const key = buildCategoryImageObjectKey(id, filename);
    const signed = await presignPut(key, contentType);
    res.json(signed);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Presign failed' });
  }
});

router.post('/categories/:id/image/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const key = req.body && req.body.key;
    if (!key || typeof key !== 'string') {
      return res.status(400).json({ error: 'key required' });
    }
    const prefix = `categories/${id}/images/`;
    if (!key.startsWith(prefix)) {
      return res.status(400).json({ error: 'Invalid key for category' });
    }
    await assertObjectExists(key);
    const url = publicUrlForKey(key);
    const category = await setCategoryImageURL(id, url);
    res.json({ imageURL: url, category });
  } catch (e) {
    console.error(e);
    const status = e.status || 500;
    res.status(status).json({ error: e.message || 'Complete failed' });
  }
});

router.post('/categories/:id/image/import-url', async (req, res) => {
  try {
    const { id } = req.params;
    const cat = await getCategory(id);
    if (!cat) return res.status(404).json({ error: 'Not found' });
    const url = parseHttpsUrl(req.body && req.body.url);
    const fn = filenameFromUrlPath(url.pathname, 'image.png');
    const key = buildCategoryImageObjectKey(id, fn);
    const ac = new AbortController();
    const timer = setTimeout(() => ac.abort(), IMAGE_IMPORT_TIMEOUT_MS);
    try {
      const { publicUrl } = await fetchUrlToR2(url, {
        maxBytes: MAX_IMAGE_IMPORT_BYTES,
        kind: 'image',
        key,
        signal: ac.signal,
      });
      const category = await setCategoryImageURL(id, publicUrl);
      res.json({ imageURL: publicUrl, category });
    } finally {
      clearTimeout(timer);
    }
  } catch (e) {
    console.error(e);
    const msg = e.name === 'AbortError' ? 'Import timed out' : e.message || 'Import failed';
    res.status(500).json({ error: msg });
  }
});

router.get('/exercises', async (_req, res) => {
  try {
    const snap = await col().get();
    const list = snap.docs.map((d) => docToExercise(d.id, d.data())).filter(Boolean);
    list.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    const payload = { exercises: list };
    try {
      JSON.stringify(payload);
    } catch (ser) {
      console.error('Exercise list JSON.stringify failed', ser);
      return res.status(500).json({ error: `Serialization failed: ${ser.message}` });
    }
    res.json(payload);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'List failed' });
  }
});

router.get('/exercises/:id', async (req, res) => {
  try {
    const d = await col().doc(req.params.id).get();
    if (!d.exists) return res.status(404).json({ error: 'Not found' });
    res.json(docToExercise(d.id, d.data()));
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Get failed' });
  }
});

router.patch('/exercises/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const body = req.body || {};
    const allowed = [
      'name',
      'description',
      'sets',
      'reps',
      'duration',
      'restTime',
      'animationURL',
      'thumbnailURL',
      'videoURL',
      'muscleGroups',
      'difficultyLevel',
      'instructions',
    ];
    const patch = {};
    for (const k of allowed) {
      if (body[k] !== undefined) patch[k] = body[k];
    }
    if (body.videoURL !== undefined && body.animationURL === undefined) {
      patch.animationURL = body.videoURL;
    }
    if (Object.keys(patch).length === 0) {
      return res.status(400).json({ error: 'No valid fields' });
    }
    patch.updatedAt = fv().serverTimestamp();
    await col().doc(id).set(patch, { merge: true });
    const d = await col().doc(id).get();
    res.json(docToExercise(d.id, d.data()));
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Patch failed' });
  }
});

router.post('/exercises/:id/presign', async (req, res) => {
  try {
    const { id } = req.params;
    const filename = (req.body && req.body.filename) || 'video.mp4';
    const contentType = (req.body && req.body.contentType) || guessContentType(filename);
    const key = buildObjectKey(id, filename);
    const signed = await presignPut(key, contentType);
    res.json(signed);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Presign failed' });
  }
});

router.post('/exercises/:id/video/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const key = req.body && req.body.key;
    if (!key || typeof key !== 'string') {
      return res.status(400).json({ error: 'key required' });
    }
    if (!key.startsWith(`exercises/${id}/`)) {
      return res.status(400).json({ error: 'Invalid key for exercise' });
    }
    await assertObjectExists(key);
    const url = publicUrlForKey(key);
    await col().doc(id).set(
      { animationURL: url, updatedAt: fv().serverTimestamp() },
      { merge: true }
    );
    const d = await col().doc(id).get();
    res.json({ animationURL: url, exercise: docToExercise(d.id, d.data()) });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Complete failed' });
  }
});

router.post('/exercises/:id/thumbnail/presign', async (req, res) => {
  try {
    const { id } = req.params;
    const filename = (req.body && req.body.filename) || 'thumbnail.jpg';
    const contentType = (req.body && req.body.contentType) || guessContentType(filename);
    const key = buildThumbnailObjectKey(id, filename);
    const signed = await presignPut(key, contentType);
    res.json(signed);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Thumbnail presign failed' });
  }
});

router.post('/exercises/:id/thumbnail/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const key = req.body && req.body.key;
    if (!key || typeof key !== 'string') {
      return res.status(400).json({ error: 'key required' });
    }
    if (!key.startsWith(`exercises/${id}/`)) {
      return res.status(400).json({ error: 'Invalid key for exercise' });
    }
    await assertObjectExists(key);
    const url = publicUrlForKey(key);
    await col().doc(id).set(
      { thumbnailURL: url, updatedAt: fv().serverTimestamp() },
      { merge: true }
    );
    const d = await col().doc(id).get();
    res.json({ thumbnailURL: url, exercise: docToExercise(d.id, d.data()) });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Thumbnail complete failed' });
  }
});

const MAX_VIDEO_IMPORT_BYTES = 500 * 1024 * 1024;
const MAX_IMAGE_IMPORT_BYTES = 15 * 1024 * 1024;
const VIDEO_IMPORT_TIMEOUT_MS = 10 * 60 * 1000;
const IMAGE_IMPORT_TIMEOUT_MS = 2 * 60 * 1000;

function filenameFromUrlPath(pathname, fallback) {
  const seg = (pathname || '').split('/').pop() || fallback;
  return seg.split('?')[0] || fallback;
}

router.post('/exercises/:id/video/import-url', async (req, res) => {
  try {
    const { id } = req.params;
    const url = parseHttpsUrl(req.body && req.body.url);
    const fn = filenameFromUrlPath(url.pathname, 'video.mp4');
    const key = buildObjectKey(id, fn);
    const ac = new AbortController();
    const timer = setTimeout(() => ac.abort(), VIDEO_IMPORT_TIMEOUT_MS);
    try {
      const { publicUrl } = await fetchUrlToR2(url, {
        maxBytes: MAX_VIDEO_IMPORT_BYTES,
        kind: 'video',
        key,
        signal: ac.signal,
      });
      await col().doc(id).set(
        { animationURL: publicUrl, updatedAt: fv().serverTimestamp() },
        { merge: true }
      );
      const d = await col().doc(id).get();
      res.json({ animationURL: publicUrl, exercise: docToExercise(d.id, d.data()) });
    } finally {
      clearTimeout(timer);
    }
  } catch (e) {
    console.error(e);
    const msg = e.name === 'AbortError' ? 'Import timed out' : e.message || 'Import failed';
    res.status(500).json({ error: msg });
  }
});

router.post('/exercises/:id/thumbnail/import-url', async (req, res) => {
  try {
    const { id } = req.params;
    const url = parseHttpsUrl(req.body && req.body.url);
    const fn = filenameFromUrlPath(url.pathname, 'thumb.jpg');
    const key = buildThumbnailObjectKey(id, fn);
    const ac = new AbortController();
    const timer = setTimeout(() => ac.abort(), IMAGE_IMPORT_TIMEOUT_MS);
    try {
      const { publicUrl } = await fetchUrlToR2(url, {
        maxBytes: MAX_IMAGE_IMPORT_BYTES,
        kind: 'image',
        key,
        signal: ac.signal,
      });
      await col().doc(id).set(
        { thumbnailURL: publicUrl, updatedAt: fv().serverTimestamp() },
        { merge: true }
      );
      const d = await col().doc(id).get();
      res.json({ thumbnailURL: publicUrl, exercise: docToExercise(d.id, d.data()) });
    } finally {
      clearTimeout(timer);
    }
  } catch (e) {
    console.error(e);
    const msg = e.name === 'AbortError' ? 'Import timed out' : e.message || 'Import failed';
    res.status(500).json({ error: msg });
  }
});

export default router;

