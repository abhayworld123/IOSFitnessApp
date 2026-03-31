import { S3Client, PutObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';
import { config, assertR2 } from './config.js';

let client;

function getClient() {
  if (client) return client;
  assertR2();
  const { accountId, accessKeyId, secretAccessKey } = config.r2;
  client = new S3Client({
    region: 'auto',
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: { accessKeyId, secretAccessKey },
    forcePathStyle: true,
  });
  return client;
}

export function guessContentType(filename) {
  const lower = filename.toLowerCase();
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.webm')) return 'video/webm';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.m4v')) return 'video/x-m4v';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'application/octet-stream';
}

export function buildObjectKey(exerciseId, filename) {
  const safe = (filename || 'video.mp4').replace(/[^a-zA-Z0-9._-]/g, '_');
  return `exercises/${exerciseId}/${randomUUID()}-${safe}`;
}

/** Thumbnail images live under `thumbnails/` to separate from demo videos. */
export function buildThumbnailObjectKey(exerciseId, filename) {
  const safe = (filename || 'thumb.jpg').replace(/[^a-zA-Z0-9._-]/g, '_');
  return `exercises/${exerciseId}/thumbnails/${randomUUID()}-${safe}`;
}

export async function presignPut(key, contentType) {
  const c = getClient();
  const cmd = new PutObjectCommand({
    Bucket: config.r2.bucket,
    Key: key,
    ContentType: contentType,
  });
  const uploadUrl = await getSignedUrl(c, cmd, { expiresIn: 3600 });
  return { uploadUrl, key, headers: { 'Content-Type': contentType } };
}

export async function assertObjectExists(key) {
  const c = getClient();
  await c.send(new HeadObjectCommand({ Bucket: config.r2.bucket, Key: key }));
}

export function publicUrlForKey(key) {
  const base = config.r2.publicBaseUrl.replace(/\/$/, '');
  const k = key.replace(/^\//, '');
  return `${base}/${k}`;
}
