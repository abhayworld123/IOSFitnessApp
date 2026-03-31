# Exercise video admin — setup runbook

Step-by-step guide to obtain credentials and run the API, admin UI, and iOS app together.

## Phase 0 — What you are wiring up

| Piece | Purpose |
|--------|--------|
| **Firebase service account** | Lets the Node server read/write Firestore as an admin (same project as the iOS app). |
| **Cloudflare R2** | Stores video files (S3-compatible). |
| **`R2_PUBLIC_BASE_URL`** | The HTTPS URL the app uses to play videos (public bucket URL or custom domain). |
| **`ADMIN_API_KEY`** | Secret only the admin web UI uses (Bearer token). Never put this in the iOS app. |
| **`PUBLIC_API_KEY`** (optional) | If set, the iOS app must send `X-App-Key` on public API calls. |
| **`CORS_ORIGINS`** | Browser origin allowed to call the API (Vite dev URL or deployed admin URL). |
| **iOS `ExerciseAPIBaseURL`** | Base URL of your deployed (or local) API so the app can call `/api/v1/...`. |

---

## Step 1 — Firebase (service account + Firestore)

1. Open [Firebase Console](https://console.firebase.google.com) and select the **same project** as `GoogleService-Info.plist` in the Fitness app.
2. **Enable Firestore** (if needed): Build → Firestore Database → create database.
3. Confirm exercise documents live in collection **`exercises`** (matches `FIRESTORE_EXERCISES_COLLECTION` in `.env.example`).
4. Create a service account key:
   - Project **gear** → **Project settings** → **Service accounts** tab.
   - **Firebase Admin SDK** → **Generate new private key** → download JSON.
5. On your machine:
   - Create `server/secrets/` (gitignored).
   - Save the file as e.g. `serviceAccount.json`.
6. In `server/.env` set `FIREBASE_SERVICE_ACCOUNT_PATH=./secrets/serviceAccount.json` (or an absolute path).
7. **Firestore rules (recommended):** Keep client reads if your app needs them; consider **denying client writes** to `exercises` if only this API should edit the catalog.

---

## Step 2 — Cloudflare R2 (bucket, keys, public URL)

1. [Cloudflare Dashboard](https://dash.cloudflare.com) → **R2**.
2. **Create bucket** (e.g. `fitness-exercise-videos`). Bucket name → `R2_BUCKET_NAME`.
3. **Account ID** on the R2 overview → `R2_ACCOUNT_ID`.
4. **S3 API credentials**:
   - R2 → **Manage R2 API Tokens** (wording may vary).
   - Create a token with read/write access to that bucket.
   - **Access Key ID** → `R2_ACCESS_KEY_ID`, **Secret Access Key** → `R2_SECRET_ACCESS_KEY` (shown once; store only in `.env`).

5. **Public URL for playback** (choose one):
   - **Public r2.dev / bucket public URL**: Enable public access per Cloudflare docs for your bucket; copy the public base URL.
   - **Custom domain** (production): Connect a domain to the bucket; use `https://videos.yourdomain.com` as the base.

6. Set `R2_PUBLIC_BASE_URL=https://your-public-host` in `server/.env` — **no trailing slash**. Final object URLs are `{R2_PUBLIC_BASE_URL}/{key}` (keys like `exercises/{exerciseId}/uuid-filename.mp4`).

7. **Bucket CORS** (required for browser upload):
   - Allow **PUT** from your admin UI origin (`http://localhost:5173` for local dev, plus production admin URL).
   - Allow required headers (at least `Content-Type`; align with the presigned request).

---

## Step 3 — Server environment (`server/.env`)

1. Copy `.env.example` to `server/.env`.
2. Fill in:

| Variable | Notes |
|----------|--------|
| `PORT` | e.g. `8787` |
| `CORS_ORIGINS` | e.g. `http://localhost:5173` (comma-separated for multiple) |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Path to service account JSON |
| `FIRESTORE_EXERCISES_COLLECTION` | Usually `exercises` |
| `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`, `R2_PUBLIC_BASE_URL` | From Step 2 |
| `ADMIN_API_KEY` | Long random secret (e.g. `openssl rand -hex 32`) |
| `PUBLIC_API_KEY` | Leave empty for open public API in dev; set for production if you want app-only access |

3. Run:

```bash
cd server
npm install
npm run dev
```

4. Smoke tests:
   - `GET http://localhost:8787/health` → `{"ok":true}`
   - With `PUBLIC_API_KEY` **unset**: `GET http://localhost:8787/api/v1/exercises`
   - With header `Authorization: Bearer <ADMIN_API_KEY>`: `GET 
---

## Step 4 — Admin web UI (`web/.env`)

1. `cd web`
2. Create `.env`:

```env
VITE_API_URL=http://localhost:8787
```

Use your deployed API URL in production.

3. `npm install && npm run dev` → open the printed URL (often `http://localhost:5173`).
4. Log in with the same value as `ADMIN_API_KEY` (sent as Bearer).
5. Select an exercise → **Upload video** or **Upload thumbnail**: presign → PUT to R2 → **complete** updates Firestore **`animationURL`** or **`thumbnailURL`**.
   - If you upload **only a video** and the exercise has no `thumbnailURL`, the admin UI tries to **auto-generate a JPEG** from the first frames of that file and upload it as the thumbnail.

---

## Step 5 — Deploy API (production)

Host the Express app on Railway, Fly.io, Render, a VPS, etc.

- Configure the **same environment variables** in the host (no committing `.env`).
- Set `CORS_ORIGINS` to your **production** admin origin(s).
- Ensure `R2_PUBLIC_BASE_URL` is reachable over **HTTPS** from devices.

---

## Step 6 — iOS app

1. Open `FitnessApp/Info.plist` in the Xcode project.
2. Set **`ExerciseAPIBaseURL`** to the API base **without** a trailing slash (e.g. `https://api.yourdomain.com`). Do not include `/api/v1`.
3. If the server has **`PUBLIC_API_KEY`** set, set **`ExerciseAPIPublicKey`** in Info.plist to the same value.
4. Rebuild. The app uses `ExerciseAPIService` and merges API + Firestore + bundled JSON.

**Note:** Simulator can use `http://localhost` if the API runs on your Mac; a **physical device** needs your LAN IP or a deployed HTTPS URL.

---

## Step 7 — End-to-end verification

1. Admin UI: after upload, Firestore shows **`animationURL`** / **`thumbnailURL`** as HTTPS URLs under your R2 public base.
2. Paste the video URL in a browser; the video should play. Open the image URL to verify the thumbnail.
3. iOS: open a workout that references that exercise; playback should use the merged catalog.

---

## Troubleshooting

| Symptom | Check |
|--------|--------|
| Presign works, upload fails | R2 **CORS** for `PUT` from the admin origin |
| Upload OK, playback fails | **`R2_PUBLIC_BASE_URL`** or public access on the bucket/domain |
| `401` on `/api/v1` | **`PUBLIC_API_KEY`** set on server but missing/wrong in the app |
| `401` on `/api/admin` | **`Authorization: Bearer`** must match **`ADMIN_API_KEY`** |
| `503` on `/api/admin` or `/api/v1` | **Firebase Admin** did not start. Open the response body in DevTools (it contains `error`). Common fixes: place a valid **service account JSON** at `server/secrets/serviceAccount.json` (full object with `project_id`, `client_email`, `private_key` — not a one-line placeholder); set `FIREBASE_SERVICE_ACCOUNT_PATH=secrets/serviceAccount.json` in `server/.env`; restart the API. Paths are resolved from the **`server/`** folder. |
| Presign / complete `500` | **R2** env incomplete or wrong **Account ID** / credentials |

---

## Related files

- [`.env.example`](.env.example) — variable list
- [`README.md`](README.md) — project overview and quick start
