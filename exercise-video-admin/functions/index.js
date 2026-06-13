/**
 * Firebase Cloud Functions (2nd gen) — HTTPS API for exercise-video-admin.
 *
 * Before first deploy, create secrets (same names as below), e.g.:
 *   firebase functions:secrets:set ADMIN_API_KEY
 *   firebase functions:secrets:set OPENROUTER_API_KEY
 *   firebase functions:secrets:set CLOUDFLARE_AI_API_TOKEN
 *   firebase functions:secrets:set R2_ACCESS_KEY_ID
 *   firebase functions:secrets:set R2_SECRET_ACCESS_KEY
 *
 * In Firebase Console → Functions → api → Environment variables, set at least:
 *   R2_ACCOUNT_ID, R2_BUCKET_NAME, R2_PUBLIC_BASE_URL, CLOUDFLARE_ACCOUNT_ID
 * Optional: CORS_ORIGINS, PUBLIC_API_KEY, OPENROUTER_MODEL, CLOUDFLARE_AI_MODEL, AI_PROVIDER_DEFAULT, FIRESTORE_* , etc.
 */
import { onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';

const ADMIN_API_KEY = defineSecret('ADMIN_API_KEY');
const OPENROUTER_API_KEY = defineSecret('OPENROUTER_API_KEY');
const CLOUDFLARE_AI_API_TOKEN = defineSecret('CLOUDFLARE_AI_API_TOKEN');
const R2_ACCESS_KEY_ID = defineSecret('R2_ACCESS_KEY_ID');
const R2_SECRET_ACCESS_KEY = defineSecret('R2_SECRET_ACCESS_KEY');

let expressApp;

async function getApp() {
  process.env.ADMIN_API_KEY = ADMIN_API_KEY.value();
  process.env.OPENROUTER_API_KEY = OPENROUTER_API_KEY.value();
  process.env.CLOUDFLARE_AI_API_TOKEN = CLOUDFLARE_AI_API_TOKEN.value();
  process.env.R2_ACCESS_KEY_ID = R2_ACCESS_KEY_ID.value();
  process.env.R2_SECRET_ACCESS_KEY = R2_SECRET_ACCESS_KEY.value();

  if (!expressApp) {
    const { createApp } = await import('./server-src/app.js');
    expressApp = createApp();
  }
  return expressApp;
}

export const api = onRequest(
  {
    region: 'us-central1',
    timeoutSeconds: 120,
    memory: '512MiB',
    invoker: 'public',
    secrets: [ADMIN_API_KEY, OPENROUTER_API_KEY, CLOUDFLARE_AI_API_TOKEN, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY],
  },
  (req, res) => {
    void getApp()
      .then((app) => {
        app(req, res);
      })
      .catch((err) => {
        console.error(err);
        if (!res.headersSent) {
          res.status(500).json({ error: 'Server initialization failed' });
        }
      });
  }
);

/** Daily 9:00 AM UTC — inactive users, streak-at-risk, server-side inbox + push. */
export const dailyNotifications = onSchedule(
  {
    schedule: '0 9 * * *',
    timeZone: 'UTC',
    region: 'us-central1',
    memory: '256MiB',
  },
  async () => {
    const { initFirebase } = await import('./server-src/firebase.js');
    const { runDailyNotificationCron } = await import('./server-src/notificationService.js');
    initFirebase();
    const result = await runDailyNotificationCron();
    console.log('dailyNotifications cron complete', result);
  }
);
