import { config } from './config.js';

export function requireAdmin(req, res, next) {
  const raw = req.headers.authorization || '';
  const token = raw.replace(/^Bearer\s+/i, '').trim();
  const expected = (config.adminApiKey || '').trim();
  if (!expected || token !== expected) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

export function requirePublicAppKey(req, res, next) {
  const required = config.publicApiKey;
  if (!required) return next();
  const requiredTrim = required.trim();
  const header = String(req.headers['x-app-key'] || '').trim();
  const bearer = (req.headers.authorization || '').replace(/^Bearer\s+/i, '').trim();
  if (header === requiredTrim || bearer === requiredTrim) return next();
  return res.status(401).json({ error: 'Invalid or missing app key' });
}
