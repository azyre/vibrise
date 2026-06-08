var shareState = (function() {
  var sharePaletteRequestId = 0;
  var shareBloomLayout = null;
  var shareBloomLayoutKey = '';
  var shareCardWidth = 1080;
  var shareCardHeight = 1352;

  function formatShareCardDateParts(date) {
    var monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return {
      month: monthNames[date.getMonth()],
      day: String(date.getDate())
    };
  }

  function getFallbackImage() {
    return 'https://placehold.co/1080x1352/1a1424/f0a050?text=%E2%99%AA';
  }

  function getCardData() {
    var currentSong = alarmRingStore.getCurrentSong();
    var now = new Date();
    var dateParts = formatShareCardDateParts(now);

    return {
      title: currentSong && currentSong.name ? currentSong.name : 'Finding music...',
      artist: currentSong && (currentSong.artist_name || currentSong.artist)
        ? (currentSong.artist_name || currentSong.artist)
        : 'Unknown Artist',
      image: currentSong && currentSong.image ? currentSong.image : getFallbackImage(),
      month: dateParts.month,
      day: dateParts.day
    };
  }

  function getFileName(data) {
    var shareData = data || getCardData();
    var safeTitle = (shareData.title || 'vibrise-share')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '')
      .slice(0, 48);

    return (safeTitle || 'vibrise-share') + '.png';
  }

  function getFallbackPalette() {
    return [
      [116, 160, 224],
      [88, 198, 168],
      [228, 160, 92]
    ];
  }

  function getRandomBloomLayout() {
    return {
      large: {
        x: 16 + Math.random() * 20,
        y: 18 + Math.random() * 20,
        radius: 80 + Math.random() * 40
      },
      small: {
        x: 62 + Math.random() * 18,
        y: 58 + Math.random() * 18,
        radius: 60 + Math.random() * 30
      }
    };
  }

  function ensureBloomLayout(data) {
    var shareData = data || getCardData();
    var key = [shareData.image, shareData.title, shareData.artist, shareData.month, shareData.day].join('|');

    if (!shareBloomLayout || shareBloomLayoutKey !== key) {
      shareBloomLayout = getRandomBloomLayout();
      shareBloomLayoutKey = key;
    }

    return shareBloomLayout;
  }

  function beginPaletteRequest() {
    sharePaletteRequestId += 1;
    return sharePaletteRequestId;
  }

  function isActivePaletteRequest(requestId) {
    return requestId === sharePaletteRequestId;
  }

  function normalizePaletteColor(color) {
    return [
      Math.max(0, Math.min(255, Math.round(color[0]))),
      Math.max(0, Math.min(255, Math.round(color[1]))),
      Math.max(0, Math.min(255, Math.round(color[2])))
    ];
  }

  function getColorLuminance(color) {
    return (0.2126 * color[0] + 0.7152 * color[1] + 0.0722 * color[2]) / 255;
  }

  function getColorSaturation(color) {
    var max = Math.max(color[0], color[1], color[2]);
    var min = Math.min(color[0], color[1], color[2]);
    return max === 0 ? 0 : (max - min) / max;
  }

  function getColorDistance(a, b) {
    var dr = a[0] - b[0];
    var dg = a[1] - b[1];
    var db = a[2] - b[2];
    return Math.sqrt(dr * dr + dg * dg + db * db);
  }

  function boostPaletteColor(color) {
    var luminance = getColorLuminance(color);
    var saturation = getColorSaturation(color);
    var boost = 1.08 + saturation * 0.18 + (0.55 - Math.min(luminance, 0.55)) * 0.28;

    return normalizePaletteColor([
      color[0] * boost,
      color[1] * boost,
      color[2] * boost
    ]);
  }

  function extractPaletteFromImage(img) {
    if (!img || !img.naturalWidth || !img.naturalHeight) return getFallbackPalette();

    var canvas = document.createElement('canvas');
    var ctx = canvas.getContext('2d', { willReadFrequently: true });
    var positions = [[1, 1], [3, 1], [6, 1], [1, 3], [4, 3], [6, 3], [1, 6], [3, 6], [6, 6], [4, 5]];
    var colors = [];
    var pair = null;
    var maxDistance = -1;
    var i;
    var j;

    canvas.width = 8;
    canvas.height = 8;
    ctx.drawImage(img, 0, 0, 8, 8);

    positions.forEach(function(position) {
      var x = position[0];
      var y = position[1];
      var data = ctx.getImageData(x, y, 1, 1).data;
      colors.push(boostPaletteColor([
        data[0] * 1.06,
        data[1] * 1.06,
        data[2] * 1.06
      ]));
    });

    for (i = 0; i < colors.length; i++) {
      for (j = i + 1; j < colors.length; j++) {
        var distance = getColorDistance(colors[i], colors[j]);
        if (distance > maxDistance) {
          maxDistance = distance;
          pair = [colors[i], colors[j]];
        }
      }
    }

    return [
      pair && pair[0] ? pair[0] : colors[0] || getFallbackPalette()[0],
      pair && pair[1] ? pair[1] : colors[1] || getFallbackPalette()[1],
      colors[4] || colors[2] || getFallbackPalette()[2]
    ];
  }

  return {
    getCardWidth: function() {
      return shareCardWidth;
    },
    getCardHeight: function() {
      return shareCardHeight;
    },
    getFallbackImage: getFallbackImage,
    getCardData: getCardData,
    getFileName: getFileName,
    getFallbackPalette: getFallbackPalette,
    ensureBloomLayout: ensureBloomLayout,
    beginPaletteRequest: beginPaletteRequest,
    isActivePaletteRequest: isActivePaletteRequest,
    extractPaletteFromImage: extractPaletteFromImage
  };
})();
