import dns from 'node:dns/promises';
import net from 'node:net';
import { Readable } from 'node:stream';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { config, assertR2 } from './config.js';
import {
  buildObjectKey,
  buildThumbnailObjectKey,
  guessContentType,
  publicUrlForKey,
} from './r2.js';

let s3Client;

async function getS3Client() {
  if (s3Client) return s3Client;
  assertR2();
  const { accountId, accessKeyId, secretAccessKey } = config.r2;
  s3Client = new S3Client({
    region: 'auto',
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: { accessKeyId, secretAccessKey },
    forcePathStyle: true,
  });
  return s3Client;
}

function isPrivateOrLocalIPv4(ip) {
  if (!net.isIPv4(ip)) return false;
  const parts = ip.split('.').map(Number);
  const [a, b] = parts;
  if (a === 10) return true;
  if (a === 127) return true;
  if (a === 0) return true;
  if (a === 169 && b === 254) return true;
  if (a === 192 && b === 168) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  return false;
}

function isBlockedHostname(hostname) {
  const h = hostname.toLowerCase();
  if (h === 'localhost' || h.endsWith('.localhost')) return true;
  if (net.isIPv4(h)) return isPrivateOrLocalIPv4(h);
  if (net.isIPv6(h)) {
    return h === '::1' || h.startsWith('fe80:') || h.startsWith('fc') || h.startsWith('fd');
  }
  return false;
}

async function assertResolvableHostSafe(hostname) {
  if (isBlockedHostname(hostname)) {
    throw new Error('URL host is not allowed');
  }
  try {
    const r = await dns.lookup(hostname, { all: true });
    for (const addr of r) {
      if (isBlockedHostname(addr.address)) {
        throw new Error('URL resolves to a disallowed address');
      }
      if (net.isIPv4(addr.address) && isPrivateOrLocalIPv4(addr.address)) {
        throw new Error('URL resolves to a disallowed address');
      }
    }
  } catch (e) {
    if (e.message.includes('disallowed') || e.message.includes('not allowed')) throw e;
    throw new Error(`DNS lookup failed: ${e.message}`);
  }
}

export function parseHttpsUrl(raw) {
  const trimmed = String(raw || '').trim();
  if (!trimmed) throw new Error('url required');
  let u;
  try {
    u = new URL(trimmed);
  } catch {
    throw new Error('Invalid URL');
  }
  if (u.protocol !== 'https:') {
    throw new Error('Only https:// URLs are allowed');
  }
  if (!u.hostname) throw new Error('Invalid URL host');
  if (isBlockedHostname(u.hostname)) {
    throw new Error('URL host is not allowed');
  }
  return u;
}

const VIDEO_TYPES = new Set([
  'video/mp4',
  'video/webm',
  'video/quicktime',
  'video/x-m4v',
  'application/octet-stream',
]);
const IMAGE_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
]);

export async function fetchUrlToR2(u, { maxBytes, kind, key, signal }) {
  await assertResolvableHostSafe(u.hostname);

  const res = await fetch(u.href, {
    method: 'GET',
    redirect: 'follow',
    signal,
    headers: { 'User-Agent': 'FitnessExerciseAdmin/1.0' },
  });

  if (!res.ok) {
    throw new Error(`Source returned HTTP ${res.status}`);
  }

  const lenHeader = res.headers.get('content-length');
  if (lenHeader) {
    const n = Number(lenHeader);
    if (Number.isFinite(n) && n > maxBytes) {
      throw new Error(`Source larger than limit (${maxBytes} bytes)`);
    }
  }

  let ct = (res.headers.get('content-type') || '').split(';')[0].trim().toLowerCase();
  if (!ct || ct === 'application/octet-stream') {
    ct = guessContentType(u.pathname);
  }

  if (kind === 'video') {
    const extOk = u.pathname.match(/\.(mp4|webm|mov|m4v)$/i);
    const typeOk = ct.startsWith('video/') || VIDEO_TYPES.has(ct);
    if (!typeOk && !extOk) {
      throw new Error(`Unexpected Content-Type for video: ${ct || 'unknown'} (or add a video extension in the path)`);
    }
  } else {
    const extOk = u.pathname.match(/\.(jpe?g|png|webp|gif)$/i);
    const typeOk = ct.startsWith('image/') || IMAGE_TYPES.has(ct);
    if (!typeOk && !extOk) {
      throw new Error(`Unexpected Content-Type for image: ${ct || 'unknown'} (or add an image extension in the path)`);
    }
  }

  if (!res.body) {
    throw new Error('Empty response body');
  }

  const reader = res.body.getReader();
  let total = 0;

  const readable = Readable.from(
    (async function* () {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        if (!value || !value.length) continue;
        total += value.length;
        if (total > maxBytes) {
          throw new Error(`Download exceeded limit (${maxBytes} bytes)`);
        }
        yield Buffer.from(value);
      }
    })()
  );

  const client = await getS3Client();
  const contentType =
    ct && ct !== 'application/octet-stream'
      ? ct
      : kind === 'video'
        ? 'video/mp4'
        : 'image/jpeg';

  await client.send(
    new PutObjectCommand({
      Bucket: config.r2.bucket,
      Key: key,
      Body: readable,
      ContentType: contentType,
    })
  );

  return { publicUrl: publicUrlForKey(key), contentType };
}
