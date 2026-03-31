import { Router } from 'express';
import { config } from '../config.js';
import { firestore } from '../firebase.js';
import { docToExercise } from '../serialize.js';

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

export default router;
