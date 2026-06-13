import { Router } from 'express';
import { config } from '../config.js';
import { firestore } from '../firebase.js';
import { docToExercise } from '../serialize.js';
import {
  readAiCoachSettingsFromFirestore,
  toPublicConfig,
  sanitizeClientMessages,
  coachCompletion,
  generateWorkoutPlan,
} from '../aiCoachService.js';
import { listCategories, getCategory } from '../categoryService.js';

const router = Router();
const col = () => firestore().collection(config.exercisesCollection);

router.get('/exercises', async (_req, res) => {
  try {
    const snap = await col().get();
    const list = snap.docs.map((d) => docToExercise(d.id, d.data())).filter(Boolean);
    list.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    res.json({ exercises: list });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'List failed' });
  }
});

router.post('/exercises/by-ids', async (req, res) => {
  try {
    const ids = req.body && req.body.ids;
    if (!Array.isArray(ids)) {
      return res.status(400).json({ error: 'ids array required' });
    }
    const uniq = [...new Set(ids.map(String))].slice(0, 300);
    const out = [];
    for (const id of uniq) {
      const d = await col().doc(id).get();
      if (d.exists) out.push(docToExercise(d.id, d.data()));
    }
    res.json({ exercises: out });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Fetch failed' });
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

// --- Workout category presentation (images + placements)

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

// --- Aura AI coach (public app key when PUBLIC_API_KEY is set)

router.get('/ai/coach/config', async (_req, res) => {
  try {
    const full = await readAiCoachSettingsFromFirestore();
    res.json(toPublicConfig(full));
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message || 'Config failed' });
  }
});

router.post('/ai/coach/generate-workout', async (req, res) => {
  try {
    const body = req.body || {};
    const bodyPart = typeof body.bodyPart === 'string' ? body.bodyPart.trim() : '';
    if (!bodyPart) {
      return res.status(400).json({ error: 'bodyPart is required' });
    }
    const userName =
      typeof body.userName === 'string' ? body.userName.trim().slice(0, 80) : '';
    const plan = await generateWorkoutPlan(bodyPart, userName || undefined);
    res.json(plan);
  } catch (e) {
    console.error(e);
    const status = e.status || 500;
    res.status(status).json({
      error: e.message?.includes('not configured')
        ? 'Coach AI is not configured on the server.'
        : e.message || 'Plan generation failed',
    });
  }
});

router.post('/ai/coach/chat', async (req, res) => {
  try {
    const body = req.body || {};
    const sanitized = sanitizeClientMessages(body.messages);
    if (!sanitized.length) {
      return res.status(400).json({ error: 'messages must include at least one user or assistant entry' });
    }
    const full = await readAiCoachSettingsFromFirestore();
    let system = full.systemPrompt;
    const name =
      typeof body.userName === 'string' ? body.userName.trim().slice(0, 80) : '';
    if (name) {
      system = `${system}\n\nThe user's first name for personalization is: ${name}.`;
    }
    const messages = [{ role: 'system', content: system }, ...sanitized];
    const reply = await coachCompletion(messages, full);
    res.json({ reply });
  } catch (e) {
    console.error(e);
    res.status(500).json({
      error: e.message?.includes('not configured')
        ? 'Coach AI is not configured on the server.'
        : e.message || 'Chat failed',
    });
  }
});

export default router;
