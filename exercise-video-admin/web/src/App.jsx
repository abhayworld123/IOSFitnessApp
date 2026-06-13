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
  getAICoachSettings,
  patchAICoachSettings,
  listCategories,
  seedCategories,
  patchCategory,
  presignCategoryImage,
  completeCategoryImageUpload,
  importCategoryImageFromUrl,
  createCategory,
} from './api.js';
import { captureFirstFrameJpegBlob } from './captureVideoPoster.js';

const DEFAULT_EXERCISE_THUMB = `${import.meta.env.BASE_URL}default-exercise-thumb.svg`;

const PLACEMENT_KEYS = ['workout_home', 'create_workout_chip', 'video_library_filter'];

export default function App() {
  const [apiKey, setApiKey] = useState(getStoredKey);
  const [loggedIn, setLoggedIn] = useState(!!getStoredKey());
  const [activePanel, setActivePanel] = useState('exercises');
  const [exercises, setExercises] = useState([]);
  const [selected, setSelected] = useState(null);
  const [categories, setCategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [categorySfSymbol, setCategorySfSymbol] = useState('');
  const [categoryWorkoutCategory, setCategoryWorkoutCategory] = useState('');
  const [categoryPlacementsJson, setCategoryPlacementsJson] = useState('{}');
  const [categoryImageURL, setCategoryImageURL] = useState('');
  const [categoryImageSourceUrl, setCategoryImageSourceUrl] = useState('');
  const [categoryUploadStatus, setCategoryUploadStatus] = useState('');
  const [showAddCategory, setShowAddCategory] = useState(false);
  const [newCategoryId, setNewCategoryId] = useState('');
  const [newCategoryWorkoutCategory, setNewCategoryWorkoutCategory] = useState('');
  const [newCategorySfSymbol, setNewCategorySfSymbol] = useState('square.grid.2x2');
  const [newCategoryPlacementsJson, setNewCategoryPlacementsJson] = useState('{}');
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

  const [aiCoachLoaded, setAiCoachLoaded] = useState(false);
  const [aiSaving, setAiSaving] = useState(false);
  const [aiSystemPrompt, setAiSystemPrompt] = useState('');
  const [aiCoachSubtitle, setAiCoachSubtitle] = useState('');
  const [aiWelcomeTagline, setAiWelcomeTagline] = useState('');
  const [aiWelcomeDisclaimer, setAiWelcomeDisclaimer] = useState('');
  const [aiLearnMoreUrl, setAiLearnMoreUrl] = useState('');
  const [aiQuickChips, setAiQuickChips] = useState('');
  const [aiProvider, setAiProvider] = useState('cloudflare');
  const [aiCloudflareModel, setAiCloudflareModel] = useState('');
  const [aiOpenRouterModel, setAiOpenRouterModel] = useState('');

  const loadAICoach = async () => {
    try {
      const s = await getAICoachSettings();
      setAiSystemPrompt(typeof s.systemPrompt === 'string' ? s.systemPrompt : '');
      setAiCoachSubtitle(typeof s.coachSubtitle === 'string' ? s.coachSubtitle : '');
      setAiWelcomeTagline(typeof s.welcomeTagline === 'string' ? s.welcomeTagline : '');
      setAiWelcomeDisclaimer(typeof s.welcomeDisclaimer === 'string' ? s.welcomeDisclaimer : '');
      setAiLearnMoreUrl(typeof s.learnMoreUrl === 'string' ? s.learnMoreUrl : '');
      setAiQuickChips(Array.isArray(s.quickChips) ? s.quickChips.join(', ') : '');
      setAiProvider(s.aiProvider === 'openrouter' ? 'openrouter' : 'cloudflare');
      setAiCloudflareModel(typeof s.cloudflareModel === 'string' ? s.cloudflareModel : '');
      setAiOpenRouterModel(typeof s.openRouterModel === 'string' ? s.openRouterModel : '');
      setAiCoachLoaded(true);
    } catch (e) {
      setErr(String(e.message || e));
    }
  };

  const saveAICoach = async () => {
    setAiSaving(true);
    setErr('');
    try {
      await patchAICoachSettings({
        systemPrompt: aiSystemPrompt,
        coachSubtitle: aiCoachSubtitle,
        welcomeTagline: aiWelcomeTagline,
        welcomeDisclaimer: aiWelcomeDisclaimer,
        learnMoreUrl: aiLearnMoreUrl,
        quickChips: aiQuickChips
          .split(',')
          .map((x) => x.trim())
          .filter(Boolean),
        aiProvider,
        cloudflareModel: aiCloudflareModel.trim() || null,
        openRouterModel: aiOpenRouterModel.trim() || null,
      });
      await loadAICoach();
    } catch (e) {
      setErr(String(e.message || e));
    } finally {
      setAiSaving(false);
    }
  };

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

  const loadCategoriesList = async () => {
    setErr('');
    setBusy(true);
    try {
      const list = await listCategories();
      setCategories(list);
    } catch (e) {
      setErr(String(e.message || e));
    } finally {
      setBusy(false);
    }
  };

  const onSeedCategories = async () => {
    setErr('');
    setBusy(true);
    try {
      const list = await seedCategories();
      setCategories(list);
    } catch (e) {
      setErr(String(e.message || e));
    } finally {
      setBusy(false);
    }
  };

  const startAddCategory = () => {
    setShowAddCategory(true);
    setSelectedCategory(null);
    setNewCategoryId('');
    setNewCategoryWorkoutCategory('');
    setNewCategorySfSymbol('square.grid.2x2');
    setNewCategoryPlacementsJson(
      JSON.stringify(
        {
          video_library_filter: { enabled: true, label: '', sortOrder: 99 },
        },
        null,
        2
      )
    );
    setErr('');
  };

  const cancelAddCategory = () => {
    setShowAddCategory(false);
  };

  const onCreateCategory = async () => {
    const id = newCategoryId.trim().toLowerCase().replace(/\s+/g, '_');
    if (!id) {
      setErr('Category id is required');
      return;
    }
    setBusy(true);
    setErr('');
    try {
      let placements = {};
      try {
        placements = JSON.parse(newCategoryPlacementsJson || '{}');
      } catch {
        throw new Error('Placements must be valid JSON');
      }
      const created = await createCategory({
        id,
        workoutCategory: newCategoryWorkoutCategory.trim() || null,
        sfSymbolFallback: newCategorySfSymbol.trim() || 'square.grid.2x2',
        placements,
      });
      await loadCategoriesList();
      setShowAddCategory(false);
      openCategory(created);
    } catch (e) {
      setErr(String(e.message || e));
    } finally {
      setBusy(false);
    }
  };

  const openCategory = (cat) => {
    setShowAddCategory(false);
    setSelectedCategory(cat);
    setCategorySfSymbol(cat.sfSymbolFallback || '');
    setCategoryWorkoutCategory(cat.workoutCategory || '');
    setCategoryPlacementsJson(JSON.stringify(cat.placements || {}, null, 2));
    setCategoryImageURL(cat.imageURL || '');
    setCategoryImageSourceUrl('');
    setCategoryUploadStatus('');
  };

  const saveCategoryMeta = async () => {
    if (!selectedCategory) return;
    setBusy(true);
    setErr('');
    try {
      let placements;
      try {
        placements = JSON.parse(categoryPlacementsJson);
      } catch {
        throw new Error('Placements must be valid JSON');
      }
      const updated = await patchCategory(selectedCategory.id, {
        sfSymbolFallback: categorySfSymbol || null,
        workoutCategory: categoryWorkoutCategory || null,
        placements,
      });
      setCategories((prev) => prev.map((c) => (c.id === updated.id ? updated : c)));
      setSelectedCategory(updated);
    } catch (e) {
      setErr(String(e.message || e));
    } finally {
      setBusy(false);
    }
  };

  const onPickCategoryImage = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file || !selectedCategory) return;
    setCategoryUploadStatus('Uploading image…');
    setErr('');
    setBusy(true);
    try {
      const ps = await presignCategoryImage(selectedCategory.id, file.name, file.type || undefined);
      await uploadFileToR2(file, ps);
      const done = await completeCategoryImageUpload(selectedCategory.id, ps.key);
      setCategoryImageURL(done.imageURL || '');
      const next = done.category;
      setCategories((prev) => prev.map((c) => (c.id === next.id ? next : c)));
      setSelectedCategory(next);
      setCategoryUploadStatus('Image upload complete.');
    } catch (err) {
      setCategoryUploadStatus('');
      setErr(String(err.message || err));
    } finally {
      setBusy(false);
    }
  };

  const onImportCategoryImageUrl = async () => {
    if (!selectedCategory) return;
    const url = categoryImageSourceUrl.trim();
    if (!url) return;
    setCategoryUploadStatus('Importing image from URL…');
    setErr('');
    setBusy(true);
    try {
      const done = await importCategoryImageFromUrl(selectedCategory.id, url);
      setCategoryImageURL(done.imageURL || '');
      const next = done.category;
      setCategories((prev) => prev.map((c) => (c.id === next.id ? next : c)));
      setSelectedCategory(next);
      setCategoryUploadStatus('Image imported to R2.');
    } catch (err) {
      setCategoryUploadStatus('');
      setErr(String(err.message || err));
    } finally {
      setBusy(false);
    }
  };

  useEffect(() => {
    if (loggedIn) {
      load();
      loadCategoriesList();
      loadAICoach();
    }
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
    <div style={{ display: 'flex', minHeight: '100vh', flexDirection: 'column' }}>
      <div
        style={{
          display: 'flex',
          gap: 8,
          padding: '12px 16px',
          borderBottom: '1px solid #2c2c2e',
          background: '#1c1c1e',
        }}
      >
        <button
          type="button"
          onClick={() => setActivePanel('exercises')}
          style={{
            ...tabBtnStyle,
            background: activePanel === 'exercises' ? '#3a3a3c' : 'transparent',
          }}
        >
          Exercises
        </button>
        <button
          type="button"
          onClick={() => setActivePanel('categories')}
          style={{
            ...tabBtnStyle,
            background: activePanel === 'categories' ? '#3a3a3c' : 'transparent',
          }}
        >
          Categories
        </button>
      </div>
      <div style={{ display: 'flex', flex: 1, minHeight: 0 }}>
      <aside
        style={{
          width: 320,
          borderRight: '1px solid #2c2c2e',
          overflowY: 'auto',
          padding: 16,
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h1 style={{ fontSize: 18, margin: 0 }}>
            {activePanel === 'categories' ? 'Categories' : 'Exercises'}
          </h1>
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
          onClick={activePanel === 'categories' ? loadCategoriesList : load}
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
        {activePanel === 'categories' && (
          <>
            <button
              type="button"
              onClick={startAddCategory}
              disabled={busy}
              style={{
                marginBottom: 8,
                width: '100%',
                padding: 8,
                borderRadius: 8,
                border: 'none',
                background: '#ff9500',
                color: '#000',
                fontWeight: 600,
                cursor: 'pointer',
              }}
            >
              Add category
            </button>
            <button
              type="button"
              onClick={onSeedCategories}
              disabled={busy}
              style={{
                marginBottom: 12,
                width: '100%',
                padding: 8,
                borderRadius: 8,
                border: '1px solid #48484a',
                background: 'transparent',
                color: '#8e8e93',
                cursor: 'pointer',
              }}
            >
              Seed missing defaults
            </button>
          </>
        )}
        {err && <p style={{ color: '#ff453a', fontSize: 13 }}>{err}</p>}
        {activePanel === 'categories' ? (
        <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          {categories.map((cat) => (
            <li key={cat.id}>
              <button
                type="button"
                onClick={() => openCategory(cat)}
                style={{
                  width: '100%',
                  textAlign: 'left',
                  padding: '10px 8px',
                  marginBottom: 4,
                  borderRadius: 8,
                  border: 'none',
                  background:
                    selectedCategory?.id === cat.id ? '#3a3a3c' : 'transparent',
                  color: '#fff',
                  cursor: 'pointer',
                }}
              >
                <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                  {cat.imageURL ? (
                    <img
                      src={cat.imageURL}
                      alt=""
                      style={{
                        width: 40,
                        height: 40,
                        borderRadius: 8,
                        objectFit: 'cover',
                        flexShrink: 0,
                        background: '#2c2c2e',
                      }}
                    />
                  ) : (
                    <div
                      style={{
                        width: 40,
                        height: 40,
                        borderRadius: 8,
                        background: '#2c2c2e',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: 10,
                        color: '#8e8e93',
                      }}
                    >
                      SF
                    </div>
                  )}
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontWeight: 600 }}>{cat.id}</div>
                    <div style={{ fontSize: 11, color: '#8e8e93' }}>
                      {cat.workoutCategory || '—'}
                    </div>
                  </div>
                </div>
              </button>
            </li>
          ))}
        </ul>
        ) : (
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
        )}
      </aside>
      <main style={{ flex: 1, padding: 24, overflowY: 'auto' }}>
        {activePanel === 'categories' ? (
          showAddCategory ? (
            <>
              <h2 style={{ marginTop: 0 }}>Add category</h2>
              <p style={{ fontSize: 12, color: '#8e8e93', marginTop: 0 }}>
                Id uses lowercase letters, numbers, underscore, or hyphen (e.g. <code>pilates</code>).
              </p>
              <label style={{ display: 'block', fontSize: 13, marginBottom: 4 }}>id *</label>
              <input
                value={newCategoryId}
                onChange={(e) => setNewCategoryId(e.target.value)}
                placeholder="pilates"
                style={inputStyle}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                workoutCategory (optional)
              </label>
              <input
                value={newCategoryWorkoutCategory}
                onChange={(e) => setNewCategoryWorkoutCategory(e.target.value)}
                placeholder="strength | cardio | yoga | …"
                style={inputStyle}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                SF Symbol fallback
              </label>
              <input
                value={newCategorySfSymbol}
                onChange={(e) => setNewCategorySfSymbol(e.target.value)}
                style={inputStyle}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                placements (JSON)
              </label>
              <textarea
                value={newCategoryPlacementsJson}
                onChange={(e) => setNewCategoryPlacementsJson(e.target.value)}
                rows={12}
                style={{ ...inputStyle, maxWidth: '100%', resize: 'vertical', fontFamily: 'monospace', fontSize: 12 }}
              />
              <div style={{ marginTop: 16, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
                <button type="button" onClick={onCreateCategory} disabled={busy} style={btnPrimary}>
                  Create category
                </button>
                <button
                  type="button"
                  onClick={cancelAddCategory}
                  disabled={busy}
                  style={{
                    ...btnPrimary,
                    background: '#3a3a3c',
                    color: '#fff',
                  }}
                >
                  Cancel
                </button>
              </div>
            </>
          ) : !selectedCategory ? (
            <p style={{ color: '#8e8e93' }}>Select a category to edit, or click Add category.</p>
          ) : (
            <>
              <h2 style={{ marginTop: 0 }}>{selectedCategory.id}</h2>
              <p style={{ fontSize: 12, color: '#8e8e93', marginTop: 0 }}>
                Placements: {PLACEMENT_KEYS.join(', ')}. Edit JSON below to toggle enabled, labels, gradients, exploreFilter.
              </p>
              <label style={{ display: 'block', fontSize: 13, marginBottom: 4 }}>workoutCategory</label>
              <input
                value={categoryWorkoutCategory}
                onChange={(e) => setCategoryWorkoutCategory(e.target.value)}
                placeholder="strength | cardio | yoga | …"
                style={inputStyle}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                SF Symbol fallback
              </label>
              <input
                value={categorySfSymbol}
                onChange={(e) => setCategorySfSymbol(e.target.value)}
                style={inputStyle}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                placements (JSON)
              </label>
              <textarea
                value={categoryPlacementsJson}
                onChange={(e) => setCategoryPlacementsJson(e.target.value)}
                rows={14}
                style={{ ...inputStyle, maxWidth: '100%', resize: 'vertical', fontFamily: 'monospace', fontSize: 12 }}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                imageURL
              </label>
              <input
                value={categoryImageURL}
                readOnly
                style={inputStyle}
              />
              <div style={{ marginTop: 16, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
                <button type="button" onClick={saveCategoryMeta} disabled={busy} style={btnPrimary}>
                  Save metadata
                </button>
                <label style={{ ...btnPrimary, cursor: busy ? 'wait' : 'pointer' }}>
                  Upload image
                  <input type="file" accept="image/*" hidden onChange={onPickCategoryImage} disabled={busy} />
                </label>
              </div>
              <div style={{ marginTop: 12, maxWidth: 560 }}>
                <label style={{ display: 'block', fontSize: 13, marginBottom: 4 }}>Image source URL</label>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
                  <input
                    value={categoryImageSourceUrl}
                    onChange={(e) => setCategoryImageSourceUrl(e.target.value)}
                    placeholder="https://…/image.png"
                    style={{ ...inputStyle, flex: '1 1 200px', margin: 0, minWidth: 0 }}
                    disabled={busy}
                  />
                  <button
                    type="button"
                    onClick={onImportCategoryImageUrl}
                    disabled={busy || !categoryImageSourceUrl.trim()}
                    style={{ ...btnPrimary, opacity: busy || !categoryImageSourceUrl.trim() ? 0.5 : 1 }}
                  >
                    Import image
                  </button>
                </div>
              </div>
              {categoryUploadStatus && (
                <p style={{ color: '#34c759', marginTop: 12 }}>{categoryUploadStatus}</p>
              )}
              {categoryImageURL ? (
                <img
                  key={categoryImageURL}
                  src={categoryImageURL}
                  alt="Category"
                  style={{ marginTop: 16, maxWidth: 280, maxHeight: 200, borderRadius: 12, objectFit: 'cover' }}
                />
              ) : (
                <p style={{ color: '#8e8e93', marginTop: 16, fontSize: 13 }}>
                  No image — app uses SF Symbol: {categorySfSymbol || '—'}
                </p>
              )}
            </>
          )
        ) : (
        <>
        <section
          style={{
            marginBottom: 28,
            padding: 16,
            borderRadius: 12,
            border: '1px solid #3a3a3c',
            background: '#2c2c2e',
          }}
        >
          <h2 style={{ marginTop: 0, marginBottom: 8, fontSize: 17 }}>Aura AI coach</h2>
          <p style={{ fontSize: 12, color: '#8e8e93', marginTop: 0, marginBottom: 12 }}>
            Prompt and copy are stored in Firestore and used by the Trakkit app. Cloudflare Workers AI is the default
            provider; OpenRouter is used as automatic backup when the primary fails. Set{' '}
            <code style={{ color: '#ffd60a' }}>CLOUDFLARE_ACCOUNT_ID</code> +{' '}
            <code style={{ color: '#ffd60a' }}>CLOUDFLARE_AI_API_TOKEN</code> and optionally{' '}
            <code style={{ color: '#ffd60a' }}>OPENROUTER_API_KEY</code> in server/.env.
          </p>
          {!aiCoachLoaded ? (
            <p style={{ color: '#8e8e93', fontSize: 13 }}>Loading coach settings…</p>
          ) : (
            <>
              <label style={{ display: 'block', fontSize: 13, marginBottom: 4 }}>System prompt</label>
              <textarea
                value={aiSystemPrompt}
                onChange={(e) => setAiSystemPrompt(e.target.value)}
                rows={6}
                placeholder="Instructions for Aura as a personal trainer…"
                style={{ ...inputStyle, maxWidth: '100%', resize: 'vertical', fontFamily: 'inherit' }}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                Coach subtitle (app header line)
              </label>
              <input
                value={aiCoachSubtitle}
                onChange={(e) => setAiCoachSubtitle(e.target.value)}
                style={{ ...inputStyle, maxWidth: '100%' }}
                placeholder="Personal Trainer | AI powered"
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                Welcome tagline
              </label>
              <input
                value={aiWelcomeTagline}
                onChange={(e) => setAiWelcomeTagline(e.target.value)}
                style={{ ...inputStyle, maxWidth: '100%' }}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                AI disclaimer text
              </label>
              <textarea
                value={aiWelcomeDisclaimer}
                onChange={(e) => setAiWelcomeDisclaimer(e.target.value)}
                rows={2}
                style={{ ...inputStyle, maxWidth: '100%', resize: 'vertical' }}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                Learn more URL (HTTPS)
              </label>
              <input
                value={aiLearnMoreUrl}
                onChange={(e) => setAiLearnMoreUrl(e.target.value)}
                style={{ ...inputStyle, maxWidth: '100%' }}
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                Quick chips (comma-separated)
              </label>
              <input
                value={aiQuickChips}
                onChange={(e) => setAiQuickChips(e.target.value)}
                style={{ ...inputStyle, maxWidth: '100%' }}
                placeholder="Full Body Workout, Quick Stretch, Cardio Session"
              />
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                AI provider (primary)
              </label>
              <select
                value={aiProvider}
                onChange={(e) => setAiProvider(e.target.value)}
                style={{ ...inputStyle, maxWidth: 400 }}
              >
                <option value="cloudflare">Cloudflare Workers AI (default)</option>
                <option value="openrouter">OpenRouter</option>
              </select>
              <label style={{ display: 'block', fontSize: 13, marginTop: 12, marginBottom: 4 }}>
                {aiProvider === 'openrouter'
                  ? 'OpenRouter model override (optional)'
                  : 'Cloudflare model override (optional)'}
              </label>
              {aiProvider === 'openrouter' ? (
                <input
                  value={aiOpenRouterModel}
                  onChange={(e) => setAiOpenRouterModel(e.target.value)}
                  style={{ ...inputStyle, maxWidth: 400 }}
                  placeholder="openai/gpt-4o-mini"
                />
              ) : (
                <input
                  value={aiCloudflareModel}
                  onChange={(e) => setAiCloudflareModel(e.target.value)}
                  style={{ ...inputStyle, maxWidth: 400 }}
                  placeholder="@cf/meta/llama-3.2-3b-instruct"
                />
              )}
              <p style={{ fontSize: 11, color: '#8e8e93', marginTop: 8, marginBottom: 0 }}>
                The other provider is used automatically as backup when the primary fails (if configured on the server).
              </p>
              <button
                type="button"
                onClick={saveAICoach}
                disabled={aiSaving || busy}
                style={{ ...btnPrimary, marginTop: 14 }}
              >
                {aiSaving ? 'Saving…' : 'Save coach settings'}
              </button>
            </>
          )}
        </section>
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
        </>
        )}
      </main>
      </div>
    </div>
  );
}

const tabBtnStyle = {
  padding: '8px 16px',
  borderRadius: 8,
  border: 'none',
  color: '#fff',
  fontWeight: 600,
  cursor: 'pointer',
};

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
