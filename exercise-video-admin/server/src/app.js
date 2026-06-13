import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './config.js';
import { initFirebase } from './firebase.js';
import { requireAdmin, requirePublicAppKey } from './middleware.js';
import adminRoutes from './routes/admin.js';
import publicRoutes from './routes/public.js';

/**
 * Express app for local Node server and Firebase Cloud Functions (onRequest).
 */
export function createApp() {
  const app = express();
  app.set('trust proxy', 1);
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

  return app;
}
