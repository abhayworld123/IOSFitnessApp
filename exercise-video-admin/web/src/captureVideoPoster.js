/**
 * Extract a JPEG poster from a local video File (object URL) so the canvas is not tainted by R2 CORS.
 * Returns null if the browser cannot decode the file or dimensions are missing.
 */
export function captureFirstFrameJpegBlob(file, { seekSeconds = 0.1, maxWidth = 720, quality = 0.85 } = {}) {
  return new Promise((resolve) => {
    if (!file?.type?.startsWith('video/')) {
      resolve(null);
      return;
    }

    const objectUrl = URL.createObjectURL(file);
    const video = document.createElement('video');
    video.muted = true;
    video.playsInline = true;
    video.setAttribute('playsinline', '');
    video.preload = 'auto';
    video.src = objectUrl;

    const cleanup = () => {
      URL.revokeObjectURL(objectUrl);
      video.removeAttribute('src');
      video.load();
    };

    let settled = false;

    const finish = (blob) => {
      if (settled) return;
      settled = true;
      cleanup();
      resolve(blob);
    };

    video.onerror = () => finish(null);

    function drawFrame() {
      try {
        const w = video.videoWidth;
        const h = video.videoHeight;
        if (!w || !h) {
          finish(null);
          return;
        }
        let cw = w;
        let ch = h;
        if (w > maxWidth) {
          cw = maxWidth;
          ch = Math.round((h * maxWidth) / w);
        }
        const canvas = document.createElement('canvas');
        canvas.width = cw;
        canvas.height = ch;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
          finish(null);
          return;
        }
        ctx.drawImage(video, 0, 0, cw, ch);
        canvas.toBlob((blob) => finish(blob || null), 'image/jpeg', quality);
      } catch {
        finish(null);
      }
    }

    video.onseeked = () => {
      drawFrame();
    };

    video.onloadeddata = () => {
      try {
        const dur = Number.isFinite(video.duration) && video.duration > 0 ? video.duration : 0;
        const t = dur > 0 ? Math.min(Math.max(seekSeconds, 0), Math.max(dur - 0.05, 0)) : 0;
        const prev = video.currentTime;
        video.currentTime = t;
        // If seek is a no-op, `seeked` may not fire — draw on next frame.
        requestAnimationFrame(() => {
          if (settled) return;
          if (video.currentTime === prev && t === prev) {
            drawFrame();
          }
        });
      } catch {
        drawFrame();
      }
    };

    setTimeout(() => {
      if (!settled) finish(null);
    }, 15000);
  });
}
