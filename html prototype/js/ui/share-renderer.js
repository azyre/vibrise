var shareRenderer = (function() {
  function getShareCardRoots() {
    var roots = [];
    var renderCard = document.getElementById('shareCard');
    var previewCard = document.getElementById('sharePreviewCard');

    if (renderCard) roots.push(renderCard);
    if (previewCard) roots.push(previewCard);

    return roots;
  }

  function applyBloomLayout(layout) {
    var currentLayout = layout || shareState.ensureBloomLayout();
    getShareCardRoots().forEach(function(root) {
      root.style.setProperty('--share-bloom-1-x', currentLayout.large.x + '%');
      root.style.setProperty('--share-bloom-1-y', currentLayout.large.y + '%');
      root.style.setProperty('--share-bloom-2-x', currentLayout.small.x + '%');
      root.style.setProperty('--share-bloom-2-y', currentLayout.small.y + '%');
    });
  }

  function applyPalette(colors) {
    var palette = colors && colors.length ? colors : shareState.getFallbackPalette();
    getShareCardRoots().forEach(function(root) {
      root.style.setProperty('--share-bloom-1', palette[0].join(', '));
      root.style.setProperty('--share-bloom-2', palette[1].join(', '));
      root.style.setProperty('--share-bloom-3', palette[2].join(', '));
    });
  }

  function populateRoot(root, data) {
    if (!root) return;

    var cover = root.querySelector('.share-card-cover');
    var bg = root.querySelector('.share-card-bg-image');
    var title = root.querySelector('.share-card-song');
    var artist = root.querySelector('.share-card-artist');
    var month = root.querySelector('.share-card-month');
    var day = root.querySelector('.share-card-day');

    if (title) title.textContent = data.title;
    if (artist) artist.textContent = data.artist;
    if (month) month.textContent = data.month;
    if (day) day.textContent = data.day;
    if (cover) {
      cover.crossOrigin = 'anonymous';
      cover.src = data.image;
    }
    if (bg) {
      bg.crossOrigin = 'anonymous';
      bg.src = data.image;
    }
  }

  function populateCard(data) {
    var cardData = data || shareState.getCardData();
    var layout = shareState.ensureBloomLayout(cardData);

    getShareCardRoots().forEach(function(root) {
      populateRoot(root, cardData);
    });

    applyBloomLayout(layout);
    syncPalette(cardData.image);
  }

  function prepareCard() {
    var data = shareState.getCardData();
    populateCard(data);
    return data;
  }

  function loadImageFromBlobUrl(blobUrl) {
    return new Promise(function(resolve, reject) {
      var img = new Image();
      img.onload = function() {
        resolve(img);
      };
      img.onerror = reject;
      img.src = blobUrl;
    });
  }

  async function loadCanvasImage(url) {
    if (!url) return null;

    try {
      var response = await fetch(url, { mode: 'cors' });
      if (!response.ok) throw new Error('Image request failed');
      var blob = await response.blob();
      var blobUrl = URL.createObjectURL(blob);

      try {
        var image = await loadImageFromBlobUrl(blobUrl);
        image._blobUrl = blobUrl;
        return image;
      } catch (error) {
        URL.revokeObjectURL(blobUrl);
        throw error;
      }
    } catch (error) {
      return null;
    }
  }

  function cleanupCanvasImage(img) {
    if (img && img._blobUrl) URL.revokeObjectURL(img._blobUrl);
  }

  async function syncPalette(imageUrl) {
    var requestId = shareState.beginPaletteRequest();
    var img = await loadCanvasImage(imageUrl);
    var palette = img ? shareState.extractPaletteFromImage(img) : shareState.getFallbackPalette();

    cleanupCanvasImage(img);
    if (!shareState.isActivePaletteRequest(requestId)) return;
    applyPalette(palette);
  }

  function roundRectPath(ctx, x, y, width, height, radius) {
    var r = Math.min(radius, width / 2, height / 2);
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + width, y, x + width, y + height, r);
    ctx.arcTo(x + width, y + height, x, y + height, r);
    ctx.arcTo(x, y + height, x, y, r);
    ctx.arcTo(x, y, x + width, y, r);
    ctx.closePath();
  }

  function drawRoundedRectFill(ctx, x, y, width, height, radius, fillStyle) {
    ctx.save();
    roundRectPath(ctx, x, y, width, height, radius);
    ctx.fillStyle = fillStyle;
    ctx.fill();
    ctx.restore();
  }

  function drawRoundedImage(ctx, img, x, y, width, height, radius) {
    ctx.save();
    roundRectPath(ctx, x, y, width, height, radius);
    ctx.clip();
    ctx.drawImage(img, x, y, width, height);
    ctx.restore();
  }

  function drawWrappedText(ctx, text, x, y, maxWidth, lineHeight, maxLines) {
    var words = String(text || '').split(/\s+/).filter(Boolean);
    var lines = [];
    var currentLine = '';

    if (!words.length) return y;

    words.forEach(function(word) {
      var testLine = currentLine ? currentLine + ' ' + word : word;
      if (ctx.measureText(testLine).width <= maxWidth || !currentLine) {
        currentLine = testLine;
        return;
      }
      lines.push(currentLine);
      currentLine = word;
    });

    if (currentLine) lines.push(currentLine);
    if (maxLines && lines.length > maxLines) {
      lines = lines.slice(0, maxLines);
      while (ctx.measureText(lines[lines.length - 1] + '...').width > maxWidth && lines[lines.length - 1].length > 1) {
        lines[lines.length - 1] = lines[lines.length - 1].slice(0, -1);
      }
      lines[lines.length - 1] += '...';
    }

    lines.forEach(function(line, index) {
      ctx.fillText(line, x, y + index * lineHeight);
    });

    return y + (lines.length - 1) * lineHeight;
  }

  function drawTextWithLetterSpacing(ctx, text, x, y, letterSpacing, align) {
    var content = String(text || '');
    var advance = 0;
    var index;

    if (!content) return;

    if (align === 'right') {
      for (index = 0; index < content.length; index++) {
        advance += ctx.measureText(content[index]).width;
        if (index < content.length - 1) advance += letterSpacing;
      }
      x -= advance;
    }

    for (index = 0; index < content.length; index++) {
      var char = content[index];
      ctx.fillText(char, x, y);
      x += ctx.measureText(char).width + letterSpacing;
    }
  }

  function drawShareCardBackground(ctx) {
    var height = shareState.getCardHeight();
    var width = shareState.getCardWidth();
    var baseGradient = ctx.createLinearGradient(0, 0, 0, height);
    baseGradient.addColorStop(0, '#121b28');
    baseGradient.addColorStop(0.54, '#101823');
    baseGradient.addColorStop(1, '#0d141d');
    ctx.fillStyle = baseGradient;
    ctx.fillRect(0, 0, width, height);
  }

  function drawShareCardWash(ctx, colors, layout) {
    var width = shareState.getCardWidth();
    var height = shareState.getCardHeight();
    var palette = colors && colors.length ? colors : shareState.getFallbackPalette();
    var bloomLayout = layout || shareState.ensureBloomLayout();

    function drawBloom(x, y, radius, color, innerAlpha, outerAlpha) {
      var gradient = ctx.createRadialGradient(x, y, 0, x, y, radius);
      gradient.addColorStop(0, 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ',' + innerAlpha + ')');
      gradient.addColorStop(0.24, 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ',' + outerAlpha + ')');
      gradient.addColorStop(0.44, 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ',' + Math.max(outerAlpha * 0.5, 0.04) + ')');
      gradient.addColorStop(0.6, 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ',' + Math.max(outerAlpha * 0.18, 0.018) + ')');
      gradient.addColorStop(0.74, 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ',' + Math.max(outerAlpha * 0.08, 0.008) + ')');
      gradient.addColorStop(1, 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ',0)');
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, width, height);
    }

    ctx.save();
    ctx.globalCompositeOperation = 'screen';
    drawBloom(
      width * (bloomLayout.large.x / 100),
      height * (bloomLayout.large.y / 100),
      width * (bloomLayout.large.radius / 100),
      palette[0],
      0.1,
      0.055
    );
    drawBloom(
      width * (bloomLayout.small.x / 100),
      height * (bloomLayout.small.y / 100),
      width * (bloomLayout.small.radius / 100),
      palette[1],
      0.05,
      0.028
    );
    ctx.restore();

    var topAmbient = ctx.createRadialGradient(540, 432, 0, 540, 432, 520);
    topAmbient.addColorStop(0, 'rgba(255,255,255,0.18)');
    topAmbient.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = topAmbient;
    ctx.fillRect(0, 0, width, height);

    var lowerVignette = ctx.createRadialGradient(540, 973, 0, 540, 973, 540);
    lowerVignette.addColorStop(0, 'rgba(0,0,0,0.1)');
    lowerVignette.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = lowerVignette;
    ctx.fillRect(0, 0, width, height);

    var overlayGradient = ctx.createLinearGradient(0, 0, 0, height);
    overlayGradient.addColorStop(0, 'rgba(8,12,18,0.06)');
    overlayGradient.addColorStop(0.42, 'rgba(8,12,18,0.2)');
    overlayGradient.addColorStop(1, 'rgba(8,12,18,0.46)');
    ctx.fillStyle = overlayGradient;
    ctx.fillRect(0, 0, width, height);
  }

  async function renderCardCanvas() {
    var data = prepareCard();
    var canvas = document.createElement('canvas');
    var ctx = canvas.getContext('2d');
    var width = shareState.getCardWidth();
    var height = shareState.getCardHeight();
    var coverImage = await loadCanvasImage(data.image);
    var bgImage = coverImage || await loadCanvasImage(shareState.getFallbackImage());
    var palette = coverImage ? shareState.extractPaletteFromImage(coverImage) : shareState.getFallbackPalette();
    var layout = shareState.ensureBloomLayout(data);

    canvas.width = width;
    canvas.height = height;

    drawShareCardBackground(ctx);

    if (bgImage) {
      ctx.save();
      ctx.globalAlpha = 1;
      ctx.filter = 'blur(160px) brightness(0.6)';
      ctx.drawImage(bgImage, -24, -41, width * 1.2, height * 1.2);
      ctx.restore();
    }

    drawShareCardWash(ctx, palette, layout);

    if (coverImage) {
      drawRoundedImage(ctx, coverImage, 110, 110, 550, 550, 44);
    } else {
      var coverGradient = ctx.createLinearGradient(110, 110, 660, 660);
      coverGradient.addColorStop(0, '#f0a050');
      coverGradient.addColorStop(1, '#6d4cff');
      drawRoundedRectFill(ctx, 110, 110, 550, 550, 44, coverGradient);
    }

    ctx.fillStyle = 'rgba(255,255,255,1)';
    ctx.font = "400 44px 'Satoshi', sans-serif";
    ctx.textBaseline = 'top';
    ctx.shadowColor = 'transparent';
    ctx.shadowBlur = 0;
    ctx.shadowOffsetY = 0;
    drawWrappedText(ctx, data.title, 110, 693, 760, 66, 1);

    ctx.save();
    ctx.fillStyle = 'rgba(255,255,255,0.2)';
    ctx.font = "400 44px 'Satoshi', sans-serif";
    ctx.globalCompositeOperation = 'lighter';
    drawWrappedText(ctx, data.artist, 110, 759, 760, 66, 1);
    ctx.restore();

    ctx.fillStyle = 'rgba(255,255,255,1)';
    ctx.font = "400 44px 'Satoshi', sans-serif";
    ctx.fillText(String(data.month || ''), 110, 1165);
    ctx.fillText(String(data.day || ''), 110, 1209);

    ctx.font = "400 99px 'Maven Pro', sans-serif";
    drawTextWithLetterSpacing(ctx, 'Vibrise', width - 110, 1154, -3.96, 'right');

    cleanupCanvasImage(coverImage);
    if (bgImage !== coverImage) cleanupCanvasImage(bgImage);

    return canvas;
  }

  return {
    prepareCard: prepareCard,
    renderCardCanvas: renderCardCanvas
  };
})();
