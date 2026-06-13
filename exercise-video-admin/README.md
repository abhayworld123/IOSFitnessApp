# Exercise video admin (R2 + Firestore + API)

Separate Node + React project for uploading exercise demonstration videos to **Cloudflare R2**, updating **`exercises`** documents in **Firestore** (`animationURL`, optional `thumbnailURL`), and serving a **public read API** used optionally by the Fitness iOS app.

**Credentials and end-to-end setup:** see [SETUP.md](SETUP.md).

## Layout

- `server/` — Express API (Firebase Admin, S3-compatible R2 presigned uploads)
- `web/` — Vite + React admin UI (API key login, list, edit metadata, upload video + thumbnail image)
- `functions/` — Firebase Cloud Functions (2nd gen) wrapper that runs the same Express app for production
- [`firebase.json`](firebase.json) + [`.firebaserc`](.firebaserc) — Firebase Hosting (static `web/dist`) + rewrites `/health` and `/api/**` → `api` function

### Production on Firebase (Hosting + Functions)

1. Install [Firebase CLI](https://firebase.google.com/docs/cli), run `firebase login`.
2. Edit [`.firebaserc`](.firebaserc) and set `default` to your **Firebase project ID** (or run `firebase use --add`).
3. Enable **Blaze** (pay-as-you-go) if prompted — Cloud Functions require it.
4. Create secrets (values match your `server/.env`):
   - `firebase functions:secrets:set ADMIN_API_KEY`
   - `firebase functions:secrets:set OPENROUTER_API_KEY`
   - `firebase functions:secrets:set CLOUDFLARE_AI_API_TOKEN`
   - `firebase functions:secrets:set R2_ACCESS_KEY_ID`
   - `firebase functions:secrets:set R2_SECRET_ACCESS_KEY`
5. In **Firebase Console → Build → Functions → api → Environment variables**, add at least:
   - `R2_ACCOUNT_ID`, `R2_BUCKET_NAME`, `R2_PUBLIC_BASE_URL`, `CLOUDFLARE_ACCOUNT_ID`
   - Optional: `CORS_ORIGINS` (e.g. `https://YOUR_PROJECT.web.app,https://your-custom-domain.com`), `PUBLIC_API_KEY`, `OPENROUTER_MODEL`, `CLOUDFLARE_AI_MODEL`, `AI_PROVIDER_DEFAULT`, `FIRESTORE_EXERCISES_COLLECTION`, `FIRESTORE_CATEGORIES_COLLECTION`, `FIRESTORE_AI_COACH_COLLECTION`, `FIRESTORE_AI_COACH_DOC`
6. From repo folder **`exercise-video-admin`**: `firebase deploy`
7. **Hosting URL** (e.g. `https://YOUR_PROJECT.web.app`) serves the admin UI; same host serves **`/api/...`** and **`/health`** via the function. Production web build uses **same-origin** `/api` (leave `VITE_API_URL` unset for `npm run build`).
8. **iOS:** set `ExerciseAPIBaseURL` to that Hosting URL (no trailing slash, no `/api/v1`).

See [SETUP.md](SETUP.md) for the full Firebase checklist.

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
- Workout categories: `GET http://localhost:8787/api/v1/categories` — optional `?placement=workout_home|create_workout_chip|video_library_filter`
- **Aura AI coach (Trakkit app):**
  - `GET /api/v1/ai/coach/config` — subtitle, tagline, disclaimer, `quickChips` (no secrets).
  - `POST /api/v1/ai/coach/chat` — body `{ "messages": [{ "role": "user"|"assistant", "content": "..." }], "userName": "optional" }` → `{ "reply": "..." }`. Uses **Cloudflare Workers AI** by default with **OpenRouter** as automatic backup.
  - `POST /api/v1/ai/coach/generate-workout` — body `{ "bodyPart": "back"|"legs"|..., "userName": "optional" }` → `{ "title", "description", "exerciseIds": [5 ids], "coachMessage" }`.

Admin (Bearer `ADMIN_API_KEY`):

- `GET/PATCH /api/admin/settings/ai-coach` — system prompt + coach copy (+ optional **`aiProvider`**, **`cloudflareModel`**, **`openRouterModel`** overrides stored in Firestore).
- Exercise catalog: `GET/PATCH /api/admin/exercises`, presign + complete for **video** and **thumbnail** (`/thumbnail/presign`, `/thumbnail/complete`)
- Workout categories: `GET/POST/PATCH /api/admin/categories`, `POST /api/admin/categories/seed`, image upload (`/image/presign`, `/image/complete`, `/image/import-url`)

### 2. Admin web UI

```bash
cd web
echo 'VITE_API_URL=http://localhost:8787' > .env
npm install
npm run dev
```

Open http://localhost:5173 — paste the same value as `ADMIN_API_KEY` to log in. Use the **Categories** tab to upload workout category images (Workout home cards, activity chips, video library filters). Edit **Aura AI coach** in the Exercises view (system prompt, subtitles, quick chips, AI provider).

### 2a. Aura AI coach (Cloudflare + OpenRouter)

**Primary (default):** [Cloudflare Workers AI REST API](https://developers.cloudflare.com/workers-ai/get-started/rest-api/). In the Cloudflare dashboard → **Workers AI** → **Use REST API**, create a Workers AI API token and copy your **Account ID**. Add to `server/.env`:

- **`CLOUDFLARE_ACCOUNT_ID`**
- **`CLOUDFLARE_AI_API_TOKEN`**
- Optional **`CLOUDFLARE_AI_MODEL`** (default `@cf/meta/llama-3.2-3b-instruct`)

**Backup / optional primary:** **`OPENROUTER_API_KEY`** from [OpenRouter](https://openrouter.ai). Optional **`OPENROUTER_MODEL`**; Firestore overrides via **`openRouterModel`** if set from the admin form.

Admins can switch the primary provider in the **Aura AI coach** panel (`cloudflare` or `openrouter`). When the primary fails, the server automatically tries the other provider if configured.

Firestore path defaults: **`FIRESTORE_AI_COACH_COLLECTION`** + **`FIRESTORE_AI_COACH_DOC`**.

### 3. R2

- Create a bucket and (recommended) a **public** custom domain or r2.dev URL.
- Set **CORS** on the bucket to allow `PUT` from your admin web origin.
- Set `R2_PUBLIC_BASE_URL` to the public URL prefix (no trailing slash).

### 4. iOS app

In `FitnessApp/Info.plist`, set:

- `ExerciseAPIBaseURL` — e.g. `https://your-api.example.com` (omit or leave empty to disable API reads). The same origin is used for **exercises**, **`/api/v1/categories`**, and **`/api/v1/ai/coach/...`**.
- `ExerciseAPIPublicKey` — only if you set `PUBLIC_API_KEY` on the server

The app merges API + Firestore + bundled JSON; video URLs prefer the API when present. The Home tab **floating chat FAB** opens **Aura AI coach** chat when the URL is configured.

## Security notes

- Never ship `ADMIN_API_KEY`, **`CLOUDFLARE_AI_API_TOKEN`**, **`OPENROUTER_API_KEY`**, or the Firebase service account in the iOS app (AI keys stay on the server).
- Prefer Firestore rules that **deny** client writes to `exercises` if only this API should edit the catalog.
