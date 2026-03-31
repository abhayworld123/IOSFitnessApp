import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '..', '.env') });

function req(name, fallback = '') {
  const v = process.env[name];
  if (v === undefined || v === '') return fallback;
  return v;
}

export const config = {
  port: parseInt(req('PORT', '8787'), 10),
  corsOrigins: req('CORS_ORIGINS', 'http://localhost:5173')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  firebaseServiceAccountPath: req('FIREBASE_SERVICE_ACCOUNT_PATH'),
  exercisesCollection: req('FIRESTORE_EXERCISES_COLLECTION', 'exercises'),
  r2: {
    accountId: req('R2_ACCOUNT_ID'),
    accessKeyId: req('R2_ACCESS_KEY_ID'),
    secretAccessKey: req('R2_SECRET_ACCESS_KEY'),
    bucket: req('R2_BUCKET_NAME'),
    publicBaseUrl: req('R2_PUBLIC_BASE_URL').replace(/\/$/, ''),
  },
  adminApiKey: req('ADMIN_API_KEY').trim(),
  publicApiKey: req('PUBLIC_API_KEY').trim(),
};

export function assertR2() {
  const { accountId, accessKeyId, secretAccessKey, bucket, publicBaseUrl } = config.r2;
  if (!accountId || !accessKeyId || !secretAccessKey || !bucket || !publicBaseUrl) {
    throw new Error('R2 env vars incomplete');
  }
}
