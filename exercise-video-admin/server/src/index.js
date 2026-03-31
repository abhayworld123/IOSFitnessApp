import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './config.js';
import { initFirebase } from './firebase.js';
import { requireAdmin, requirePublicAppKey } from './middleware.js';
import adminRoutes from './routes/admin.js';
import publicRoutes from './routes/public.js';

const app = express();
app.use(helmet());
app.use(
  cors({
    origin: config.corsOrigins.length ? config.corsOrigins : true,
    credentials: true,
  })
);
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => res.json({ ok: true }));

function requireFirebase(_req, res, next) {
  try {
    initFirebase();
    next();
  } catch (e) {
    res.status(503).json({ error: e.message || 'Firebase not configured' });
  }
}

app.use('/api/v1', requireFirebase, requirePublicAppKey, publicRoutes);
app.use('/api/admin', requireFirebase, requireAdmin, adminRoutes);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: err.message || 'Server error' });
});

app.listen(config.port, () => {
  console.log(`Exercise video admin API on http://localhost:${config.port}`);
});
