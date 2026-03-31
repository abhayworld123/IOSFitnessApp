import { useEffect, useState } from 'react';
import {
  listExercises,
  patchExercise,
  presign,
  presignThumbnail,
  completeUpload,
  completeThumbnailUpload,
  uploadFileToR2,
  importVideoFromUrl,
  importThumbnailFromUrl,
  getStoredKey,
  setStoredKey,
} from './api.js';
import { captureFirstFrameJpegBlob } from './captureVideoPoster.js';

const DEFAULT_EXERCISE_THUMB = `${import.meta.env.BASE_URL}default-exercise-thumb.svg`;

export default function App() {
  const [apiKey, setApiKey] = useState(getStoredKey);
  const [loggedIn, setLoggedIn] = useState(!!getStoredKey());
  const [exercises, setExercises] = useState([]);
  const [selected, setSelected] = useState(null);
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [animationURL, setAnimationURL] = useState('');
  const [thumbnailURL, setThumbnailURL] = useState('');
  const [uploadStatus, setUploadStatus] = useState('');
  const [thumbUploadStatus, setThumbUploadStatus] = useState('');
  const [videoSourceUrl, setVideoSourceUrl] = useState('');
  const [thumbSourceUrl, setThumbSourceUrl] = useState('');

  const load = async () => {
    setErr('');
    setBusy(true);
    try {
      const list = await listExercises();
      setExercises(list);
    } catch (e) {
      setErr(String(e.message || e));
    } finally {
      setBusy(false);
    }
  };

  useEffect(() => {
    if (loggedIn) load();
  }, [loggedIn]);

  const login = () => {
    setStoredKey(apiKey.trim());
    setLoggedIn(!!apiKey.trim());
    setErr('');
  };

  const logout = () => {
    setStoredKey('');
    setApiKey('');
    setLoggedIn(false);
    setExercises([]);
    setSelected(null);
  };

  const openExercise = (ex) => {
    setSelected(ex);
    setName(ex.name || '');
    setDescription(ex.description || '');
    setAnimationURL(ex.animationURL || ex.videoURL || '');
    setThumbnailURL(ex.thumbnailURL || '');
    setUploadStatus('');
    setThumbUploadStatus('');
    setVideoSourceUrl('');
    setThumbSourceUrl('');
  };

  const saveMeta = async () => {
    if (!selected) return;
    setBusy(true);
    setErr('');
    try {
      const updated = await patchExercise(selected.id, {
        name,
        description,
        animationURL: animationURL || null,
        thumbnailURL: thumbnailURL || null,
      });
      setExercises((prev) =>
        prev.map((x) => (x.id === updated.id ? updated : x))
      );
      setSelected(updated);
    } catch (e) {
      setErr(String(e.message || e));
    } finally {
      setBusy(false);
    }
  };

  const onPickFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file || !selected) return;
    setUploadStatus('Uploading…');
    setErr('');
    setBusy(true);
    try {
      const ps = await presign(selected.id, file.name, file.type || undefined);
      await uploadFileToR2(file, ps);
      const done = await completeUpload(selected.id, ps.key);
      setAnimationURL(done.animationURL || '');
      let nextExercise = done.exercise;
      if (!nextExercise.thumbnailURL) {
        setThumbUploadStatus('Generating thumbnail from video…');
        const jpeg = await captureFirstFrameJpegBlob(file);
        if (jpeg) {
          try {
            const psThumb = await presignThumbnail(selected.id, 'auto-poster.jpg', 'image/jpeg');
            const posterFile = new File([jpeg], 'auto-poster.jpg', { type: 'image/jpeg' });
            await uploadFileToR2(posterFile, psThumb);
            const doneThumb = await completeThumbnailUpload(selected.id, psThumb.key);
            nextExercise = doneThumb.exercise;
            setThumbnailURL(doneThumb.thumbnailURL || '');
            setThumbUploadStatus('Thumbnail auto-generated from video.');
          } catch (thumbErr) {
            console.warn('Auto thumbnail failed', thumbErr);
            setThumbUploadStatus('');
          }
        } else {
          setThumbUploadStatus('');
        }
      }
      setExercises((prev) =>
        prev.map((x) =>
          x.id === nextExercise.id ? nextExercise : x
        )
      );
      setSelected(nextExercise);
      setUploadStatus('Upload complete.');
    } catch (err) {
      setUploadStatus('');
      setErr(String(err.message || err));
    } finally {
      setBusy(false);
    }
  };

  const onPickThumbnail = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file || !selected) return;
    setThumbUploadStatus('Uploading thumbnail…');
    setErr('');
    setBusy(true);
    try {
      const ps = await presignThumbnail(selected.id, file.name, file.type || undefined);
      await uploadFileToR2(file, ps);
      const done = await completeThumbnailUpload(selected.id, ps.key);
      setThumbnailURL(done.thumbnailURL || '');
      setExercises((prev) =>
        prev.map((x) =>
          x.id === done.exercise.id ? done.exercise : x
        )
      );
      setSelected(done.exercise);
      setThumbUploadStatus('Thumbnail upload complete.');
    } catch (err) {
      setThumbUploadStatus('');
      setErr(String(err.message || err));
    } finally {
      setBusy(false);
    }
  };

  const onImportVideoUrl = async () => {
    if (!selected) return;
    const url = videoSourceUrl.trim();
    if (!url) return;
    setUploadStatus('Importing video from URL…');
    setErr('');
    setBusy(true);
    try {
      const done = await importVideoFromUrl(selected.id, url);
      setAnimationURL(done.animationURL || '');
      const nextExercise = done.exercise;
      setExercises((prev) =>
        prev.map((x) => (x.id === nextExercise.id ? nextExercise : x))
      );
      setSelected(nextExercise);
      setUploadStatus('Video imported to R2.');
    } catch (err) {
      setUploadStatus('');
      setErr(String(err.message || err));
    } finally {
      setBusy(false);
    }
  };

  const onImportThumbUrl = async () => {
    if (!selected) return;
    const url = thumbSourceUrl.trim();
    if (!url) return;
    setThumbUploadStatus('Importing thumbnail from URL…');
    setErr('');
    setBusy(true);
    try {
      const done = await importThumbnailFromUrl(selected.id, url);
      setThumbnailURL(done.thumbnailURL || '');
      setExercises((prev) =>
        prev.map((x) => (x.id === done.exercise.id ? done.exercise : x))
      );
      setSelected(done.exercise);
      setThumbUploadStatus('Thumbnail imported to R2.');
    } catch (err) {
      setThumbUploadStatus('');
      setErr(String(err.message || err));
    } finally {
      setBusy(false);
    }
  };

  if (!loggedIn) {
    return (
      <div style={{ maxWidth: 420, margin: '80px auto', padding: 24 }}>
        <h1 style={{ fontSize: 22, marginBottom: 8 }}>Exercise video admin</h1>
        <p style={{ color: '#8e8e93', fontSize: 14, marginBottom: 20 }}>
          API: {import.meta.env.VITE_API_URL?.trim()
            ? import.meta.env.VITE_API_URL
            : import.meta.env.DEV
              ? 'Vite proxy → http://localhost:8787 (or set VITE_API_URL)'
              : '(set VITE_API_URL for production build)'}
        </p>
        <label style={{ display: 'block', fontSize: 13, marginBottom: 6 }}>Admin API key</label>
        <input
          type="password"
          value={apiKey}
          onChange={(e) => setApiKey(e.target.value)}
          style={{
            width: '100%',
            padding: 10,
            borderRadius: 8,
            border: '1px solid #3a3a3c',
            background: '#1c1c1e',
            color: '#fff',
          }}
          placeholder="Bearer value from ADMIN_API_KEY"
        />
        <button
          type="button"
          onClick={login}
          style={{
            marginTop: 16,
            padding: '10px 20px',
            borderRadius: 8,
            border: 'none',
            background: '#ff9500',
            color: '#000',
            fontWeight: 600,
            cursor: 'pointer',
          }}
        >
          Continue
        </button>
        {err && <p style={{ color: '#ff453a', marginTop: 12 }}>{err}</p>}
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      <aside
        style={{
          width: 320,
          borderRight: '1px solid #2c2c2e',
          overflowY: 'auto',
          padding: 16,
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h1 style={{ fontSize: 18, margin: 0 }}>Exercises</h1>
          <button
            type="button"
            onClick={logout}
            style={{
              fontSize: 12,
              background: 'transparent',
              border: '1px solid #48484a',
              color: '#8e8e93',
              borderRadius: 6,
              padding: '4px 8px',
              cursor: 'pointer',
            }}
          >
            Log out
          </button>
        </div>
        <button
          type="button"
          onClick={load}
          disabled={busy}
          style={{
            marginTop: 12,
            marginBottom: 12,
            width: '100%',
            padding: 8,
            borderRadius: 8,
            border: 'none',
            background: '#2c2c2e',
            color: '#fff',
            cursor: 'pointer',
          }}
        >
          Refresh
        </button>
        {err && <p style={{ color: '#ff453a', fontSize: 13 }}>{err}</p>}
        <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          {exercises.map((ex) => (
            <li key={ex.id}>
              <button
                type="button"
                onClick={() => openExercise(ex)}
                style={{
                  width: '100%',
                  textAlign: 'left',
                  padding: '10px 8px',
                  marginBottom: 4,
                  borderRadius: 8,
                  border: 'none',
                  background:
                    selected?.id === ex.id ? '#3a3a3c' : 'transparent',
                  color: '#fff',
                  cursor: 'pointer',
                }}
              >
                <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                  <img
                    src={ex.thumbnailURL || DEFAULT_EXERCISE_THUMB}
                    alt=""
                    style={{
                      width: 40,
                      height: 40,
                      borderRadius: 8,
                      objectFit: 'cover',
                      flexShrink: 0,
                      background: '#2c2c2e',
                    }}
                    onError={(e) => {
                      e.target.src = DEFAULT_EXERCISE_THUMB;
                    }}
                  />
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontWeight: 600 }}>{ex.name || ex.id}</div>
                    <div style={{ fontSize: 11, color: '#8e8e93' }}>{ex.id}</div>
                  </div>
                </div>
              </button>
            </li>
          ))}
        </ul>
      </aside>
      <main style={{ flex: 1, padding: 24, overflowY: 'auto' }}>
        {!selected ? (
          <p style={{ color: '#8e8e93' }}>Select an exercise.</p>
        ) : (
          <>
            <h2 style={{ marginTop: 0 }}>{selected.id}</h2>
            <label style={{ display: 'block', fontSize: 13, marginBottom: 4 }}>Name</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              style={inputStyle}
            />
            <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
              Description
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={4}
              style={{ ...inputStyle, resize: 'vertical' }}
            />
            <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
              animationURL (video)
            </label>
            <input
              value={animationURL}
              onChange={(e) => setAnimationURL(e.target.value)}
              style={inputStyle}
            />
            <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
              thumbnailURL (image)
            </label>
            <input
              value={thumbnailURL}
              onChange={(e) => setThumbnailURL(e.target.value)}
              style={inputStyle}
            />
            <div style={{ marginTop: 16, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
              <button
                type="button"
                onClick={saveMeta}
                disabled={busy}
                style={btnPrimary}
              >
                Save metadata
              </button>
              <label style={{ ...btnPrimary, cursor: busy ? 'wait' : 'pointer' }}>
                Upload video
                <input type="file" accept="video/*" hidden onChange={onPickFile} disabled={busy} />
              </label>
              <label style={{ ...btnPrimary, cursor: busy ? 'wait' : 'pointer' }}>
                Upload thumbnail
                <input type="file" accept="image/*" hidden onChange={onPickThumbnail} disabled={busy} />
              </label>
            </div>
            <p style={{ fontSize: 12, color: '#8e8e93', marginTop: 14, marginBottom: 6 }}>
              Or import from HTTPS (server downloads and stores in R2; large files may take minutes).
            </p>
            <div style={{ marginTop: 4, maxWidth: 560 }}>
              <label style={{ display: 'block', fontSize: 13, marginBottom: 4 }}>Video source URL</label>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
                <input
                  value={videoSourceUrl}
                  onChange={(e) => setVideoSourceUrl(e.target.value)}
                  placeholder="https://…/file.mp4"
                  style={{ ...inputStyle, flex: '1 1 200px', margin: 0, minWidth: 0 }}
                  disabled={busy}
                />
                <button
                  type="button"
                  onClick={onImportVideoUrl}
                  disabled={busy || !videoSourceUrl.trim()}
                  style={{ ...btnPrimary, opacity: busy || !videoSourceUrl.trim() ? 0.5 : 1 }}
                >
                  Import video
                </button>
              </div>
            </div>
            <div style={{ marginTop: 12, maxWidth: 560 }}>
              <label style={{ display: 'block', fontSize: 13, marginBottom: 4 }}>Thumbnail source URL</label>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
                <input
                  value={thumbSourceUrl}
                  onChange={(e) => setThumbSourceUrl(e.target.value)}
                  placeholder="https://…/image.jpg"
                  style={{ ...inputStyle, flex: '1 1 200px', margin: 0, minWidth: 0 }}
                  disabled={busy}
                />
                <button
                  type="button"
                  onClick={onImportThumbUrl}
                  disabled={busy || !thumbSourceUrl.trim()}
                  style={{ ...btnPrimary, opacity: busy || !thumbSourceUrl.trim() ? 0.5 : 1 }}
                >
                  Import thumbnail
                </button>
              </div>
            </div>
            {uploadStatus && (
              <p style={{ color: '#34c759', marginTop: 12 }}>{uploadStatus}</p>
            )}
            {thumbUploadStatus && (
              <p style={{ color: '#34c759', marginTop: 12 }}>{thumbUploadStatus}</p>
            )}
            {animationURL ? (
              <video
                key={animationURL}
                src={animationURL}
                controls
                poster={thumbnailURL || undefined}
                style={{ marginTop: 16, maxWidth: '100%', maxHeight: 360, borderRadius: 12 }}
              />
            ) : thumbnailURL ? (
              <img
                key={thumbnailURL}
                src={thumbnailURL}
                alt="Thumbnail"
                style={{ marginTop: 16, maxWidth: 280, maxHeight: 200, borderRadius: 12, objectFit: 'cover' }}
              />
            ) : (
              <img
                src={DEFAULT_EXERCISE_THUMB}
                alt=""
                style={{ marginTop: 16, maxWidth: 280, maxHeight: 200, borderRadius: 12, objectFit: 'cover' }}
              />
            )}
          </>
        )}
      </main>
    </div>
  );
}

const inputStyle = {
  width: '100%',
  maxWidth: 560,
  padding: 10,
  borderRadius: 8,
  border: '1px solid #3a3a3c',
  background: '#1c1c1e',
  color: '#fff',
};

const btnPrimary = {
  padding: '10px 16px',
  borderRadius: 8,
  border: 'none',
  background: '#ff9500',
  color: '#000',
  fontWeight: 600,
  cursor: 'pointer',
  display: 'inline-block',
};
