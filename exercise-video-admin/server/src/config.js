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
  categoriesCollection: req('FIRESTORE_CATEGORIES_COLLECTION', 'categories'),
  r2: {
    accountId: req('R2_ACCOUNT_ID'),
    accessKeyId: req('R2_ACCESS_KEY_ID'),
    secretAccessKey: req('R2_SECRET_ACCESS_KEY'),
    bucket: req('R2_BUCKET_NAME'),
    publicBaseUrl: req('R2_PUBLIC_BASE_URL').replace(/\/$/, ''),
  },
  adminApiKey: req('ADMIN_API_KEY').trim(),
  publicApiKey: req('PUBLIC_API_KEY').trim(),
  /** OpenRouter (server-only): https://openrouter.ai */
  openRouterApiKey: req('OPENROUTER_API_KEY').trim(),
  openRouterModel: req('OPENROUTER_MODEL', 'openai/gpt-4o-mini'),
  /** Cloudflare Workers AI REST (server-only): https://developers.cloudflare.com/workers-ai/get-started/rest-api/ */
  cloudflareAccountId: req('CLOUDFLARE_ACCOUNT_ID').trim(),
  cloudflareAiApiToken: req('CLOUDFLARE_AI_API_TOKEN').trim(),
  cloudflareAiModel: req('CLOUDFLARE_AI_MODEL', '@cf/meta/llama-3.2-3b-instruct'),
  aiProviderDefault: req('AI_PROVIDER_DEFAULT', 'cloudflare').trim().toLowerCase(),
  aiCoachFirestoreCollection: req('FIRESTORE_AI_COACH_COLLECTION', 'trakkit_admin_settings'),
  aiCoachFirestoreDocId: req('FIRESTORE_AI_COACH_DOC', 'ai_coach'),
};

export function assertR2() {
  const { accountId, accessKeyId, secretAccessKey, bucket, publicBaseUrl } = config.r2;
  if (!accountId || !accessKeyId || !secretAccessKey || !bucket || !publicBaseUrl) {
    throw new Error('R2 env vars incomplete');
  }
}
