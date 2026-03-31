# Exercise video admin (R2 + Firestore + API)

Separate Node + React project for uploading exercise demonstration videos to **Cloudflare R2**, updating **`exercises`** documents in **Firestore** (`animationURL`, optional `thumbnailURL`), and serving a **public read API** used optionally by the Fitness iOS app.

**Credentials and end-to-end setup:** see [SETUP.md](SETUP.md).

## Layout

- `server/` — Express API (Firebase Admin, S3-compatible R2 presigned uploads)
- `web/` — Vite + React admin UI (API key login, list, edit metadata, upload video + thumbnail image)

## Quick start

### 1. Server

```bash
cd server
cp ../.env.example .env
# Edit .env: Firebase service account path, R2 credentials, ADMIN_API_KEY, R2_PUBLIC_BASE_URL
mkdir -p secrets
# Place your Firebase service account JSON at secrets/serviceAccount.json
npm install
npm run dev
```

- Health: `GET http://localhost:8787/health`
- Public catalog: `GET http://localhost:8787/api/v1/exercises` (optional `PUBLIC_API_KEY` → send `X-App-Key`)
- Batch: `POST http://localhost:8787/api/v1/exercises/by-ids` with JSON `{ "ids": ["ex_001", ...] }`
- Admin (Bearer `ADMIN_API_KEY`): `GET/PATCH /api/admin/exercises`, presign + complete for **video** and **thumbnail** (`/thumbnail/presign`, `/thumbnail/complete`)

### 2. Admin web UI

```bash
cd web
echo 'VITE_API_URL=http://localhost:8787' > .env
npm install
npm run dev
```

Open http://localhost:5173 — paste the same value as `ADMIN_API_KEY` to log in.

### 3. R2

- Create a bucket and (recommended) a **public** custom domain or r2.dev URL.
- Set **CORS** on the bucket to allow `PUT` from your admin web origin.
- Set `R2_PUBLIC_BASE_URL` to the public URL prefix (no trailing slash).

### 4. iOS app

In `FitnessApp/Info.plist`, set:

- `ExerciseAPIBaseURL` — e.g. `https://your-api.example.com` (omit or leave empty to disable API reads)
- `ExerciseAPIPublicKey` — only if you set `PUBLIC_API_KEY` on the server

The app merges API + Firestore + bundled JSON; video URLs prefer the API when present.

## Security notes

- Never ship `ADMIN_API_KEY` or the Firebase service account in the iOS app.
- Prefer Firestore rules that **deny** client writes to `exercises` if only this API should edit the catalog.
