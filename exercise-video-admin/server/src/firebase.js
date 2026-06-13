import admin from 'firebase-admin';
import { readFileSync, existsSync } from 'fs';
import { dirname, join, isAbsolute } from 'path';
import { fileURLToPath } from 'url';
import { config } from './config.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

/** Resolve paths in .env relative to the server/ folder (not shell CWD). */
function resolveServiceAccountPath(p) {
  if (!p || !p.trim()) return '';
  const trimmed = p.trim();
  if (isAbsolute(trimmed)) return trimmed;
  return join(__dirname, '..', trimmed);
}

let initialized = false;

function useApplicationDefaultCredentials() {
  return (
    process.env.USE_GOOGLE_APPLICATION_CREDENTIALS === '1' ||
    Boolean(process.env.FUNCTION_TARGET) ||
    Boolean(process.env.K_SERVICE) ||
    Boolean(process.env.CLOUD_RUN_JOB)
  );
}

export function initFirebase() {
  if (initialized) return;

  if (useApplicationDefaultCredentials()) {
    try {
      admin.initializeApp();
    } catch (e) {
      throw new Error(`Firebase initializeApp (ADC) failed: ${e.message || e}`);
    }
    initialized = true;
    return;
  }

  const rawPath = config.firebaseServiceAccountPath;
  const path = resolveServiceAccountPath(rawPath);
  if (!path || !existsSync(path)) {
    throw new Error(
      `Service account file not found. Resolved path: "${path || '(empty)'}". Set FIREBASE_SERVICE_ACCOUNT_PATH in server/.env (e.g. secrets/serviceAccount.json), or run on Cloud Functions / Cloud Run with a service account that can access Firestore.`
    );
  }
  let sa;
  try {
    const text = readFileSync(path, 'utf8');
    sa = JSON.parse(text);
  } catch (e) {
    if (e instanceof SyntaxError) {
      throw new Error(
        `Invalid JSON in service account file "${path}". Download a fresh key from Firebase Console → Project settings → Service accounts.`
      );
    }
    throw e;
  }
  if (!sa.private_key || !sa.client_email || !sa.project_id) {
    throw new Error(
      `Service account JSON is missing required fields (project_id, client_email, private_key). File: "${path}"`
    );
  }
  try {
    admin.initializeApp({ credential: admin.credential.cert(sa) });
  } catch (e) {
    throw new Error(`Firebase initializeApp failed: ${e.message || e}`);
  }
  initialized = true;
}

export function firestore() {
  if (!initialized) initFirebase();
  return admin.firestore();
}

export function fv() {
  if (!initialized) initFirebase();
  return admin.firestore.FieldValue;
}
