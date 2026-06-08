// ====== BACKGROUNDS ======

function applyWeatherToHome() {
  return weatherService.getLocation().then(function(loc) {
    return weatherService.fetchWeather(loc.lat, loc.lon);
  }).then(function(weather) {
    var code = weather ? weather.weathercode : 2;
    var temp = weather ? weather.temperature : 20;
    var style = weatherService.generateWeatherStyle(code, temp);
    weatherService.spiceUpStyle(style);

    var daylight = weatherService.getDaylightFactor();
    var brightness = (0.5 + 0.7 * daylight).toFixed(2);
    var saturation = (1.1 + 0.4 * daylight).toFixed(2);

    var bgBase = document.getElementById('homeBgBase');
    bgBase.style.backgroundImage = 'none';
    bgBase.style.background = style.bg;
    bgBase.style.filter = 'brightness(' + brightness + ') saturate(' + saturation + ')';

    startFlowOrbs(style.colors, 0.35 + 0.35 * daylight);
    document.getElementById('homeBg').classList.add('visible');
  });
}

var flowAnimFrame = null;

function extractColorsAndAnimate(imgUrl, idPrefix) {
  var canvas = document.createElement('canvas');
  var ctx = canvas.getContext('2d');
  var img = new Image();
  var prefix = idPrefix || 'flowOrb';
  img.crossOrigin = 'anonymous';

  img.onload = function() {
    canvas.width = 8;
    canvas.height = 8;
    ctx.drawImage(img, 0, 0, 8, 8);
    var data = ctx.getImageData(0, 0, 8, 8).data;

    var colors = [];
    var positions = [[0, 0], [7, 0], [0, 7], [7, 7], [3, 3], [5, 2], [2, 5], [6, 4]];
    for (var p = 0; p < positions.length; p++) {
      var x = positions[p][0];
      var y = positions[p][1];
      var idx = (y * 8 + x) * 4;
      colors.push([data[idx], data[idx + 1], data[idx + 2]]);
    }

    startFlowOrbs(colors, null, prefix);
  };

  img.onerror = function() {
    startFlowOrbs([
      [240, 160, 80],
      [100, 120, 200],
      [180, 100, 160],
      [120, 200, 150]
    ], null, prefix);
  };

  img.src = imgUrl;
}

function startFlowOrbs(colors, baseOpacity, idPrefix) {
  var bOp = baseOpacity != null ? baseOpacity : 0.55;
  var prefix = idPrefix || 'flowOrb';
  var orbs = [];
  var sizeRanges = [[100, 160], [180, 260], [130, 210]];

  for (var i = 0; i < 3; i++) {
    var c1 = colors[i % colors.length];
    var c2 = colors[(i + 2) % colors.length];
    var minS = sizeRanges[i][0];
    var maxS = sizeRanges[i][1];
    var size = Math.round(minS + Math.random() * (maxS - minS));
    var el = document.getElementById(prefix + i);

    el.style.width = size + 'px';
    el.style.height = size + 'px';
    el.style.background =
      'radial-gradient(circle, rgba(' + c1[0] + ',' + c1[1] + ',' + c1[2] + ',0.5), rgba(' +
      c2[0] + ',' + c2[1] + ',' + c2[2] + ',0.2) 70%, transparent)';
    el.style.opacity = bOp + Math.random() * 0.2;

    orbs.push({
      el: el,
      x: Math.random() * 390,
      y: Math.random() * 844,
      vx: (Math.random() - 0.5) * 0.6,
      vy: (Math.random() - 0.5) * 0.6,
      ax: 0,
      ay: 0
    });
  }

  if (flowAnimFrame) cancelAnimationFrame(flowAnimFrame);

  function animate() {
    for (var j = 0; j < orbs.length; j++) {
      var orb = orbs[j];
      orb.ax += (Math.random() - 0.5) * 0.02;
      orb.ay += (Math.random() - 0.5) * 0.02;
      orb.ax *= 0.98;
      orb.ay *= 0.98;
      orb.vx += orb.ax;
      orb.vy += orb.ay;
      orb.vx = Math.max(-0.8, Math.min(0.8, orb.vx));
      orb.vy = Math.max(-0.8, Math.min(0.8, orb.vy));
      orb.x += orb.vx;
      orb.y += orb.vy;

      if (orb.x < -80) orb.vx = Math.abs(orb.vx) * 0.6 + 0.1;
      if (orb.x > 350) orb.vx = -Math.abs(orb.vx) * 0.6 - 0.1;
      if (orb.y < -80) orb.vy = Math.abs(orb.vy) * 0.6 + 0.1;
      if (orb.y > 750) orb.vy = -Math.abs(orb.vy) * 0.6 - 0.1;

      orb.el.style.transform = 'translate(' + orb.x + 'px, ' + orb.y + 'px)';
    }

    flowAnimFrame = requestAnimationFrame(animate);
  }

  animate();
}

function applyWeatherToRing(weather) {
  var code = weather ? weather.weathercode : 2;
  var temp = weather ? weather.temperature : 20;
  var style = weatherService.generateWeatherStyle(code, temp);
  weatherService.spiceUpStyle(style);

  var daylight = weatherService.getDaylightFactor();
  var brightness = (0.5 + 0.7 * daylight).toFixed(2);
  var saturation = (1.1 + 0.4 * daylight).toFixed(2);

  var bgBase = document.getElementById('ringBgBase');
  bgBase.style.backgroundImage = 'none';
  bgBase.style.background = style.bg;
  bgBase.style.filter = 'brightness(' + brightness + ') saturate(' + saturation + ')';

  var albumBg = document.getElementById('ringBgAlbum');
  albumBg.style.opacity = '0';
  albumBg.style.backgroundImage = 'none';

  startFlowOrbs(style.colors, 0.35 + 0.35 * daylight, 'ringFlowOrb');
  document.getElementById('ringBg').classList.add('visible');
}

function syncHomeBackgroundToRing() {
  var homeBg = document.getElementById('homeBg');
  var homeBgBase = document.getElementById('homeBgBase');
  var ringBg = document.getElementById('ringBg');
  var ringBgBase = document.getElementById('ringBgBase');
  var ringAlbumBg = document.getElementById('ringBgAlbum');

  if (!homeBg || !homeBgBase || !ringBg || !ringBgBase) return false;
  if (!homeBg.classList.contains('visible')) return false;

  var homeBaseStyle = window.getComputedStyle(homeBgBase);
  ringBgBase.style.background = homeBaseStyle.background;
  ringBgBase.style.backgroundImage = homeBaseStyle.backgroundImage;
  ringBgBase.style.backgroundPosition = homeBaseStyle.backgroundPosition;
  ringBgBase.style.backgroundSize = homeBaseStyle.backgroundSize;
  ringBgBase.style.filter = homeBaseStyle.filter;

  if (ringAlbumBg) {
    ringAlbumBg.style.opacity = '0';
    ringAlbumBg.style.backgroundImage = 'none';
  }

  for (var i = 0; i < 3; i++) {
    var homeOrb = document.getElementById('flowOrb' + i);
    var ringOrb = document.getElementById('ringFlowOrb' + i);
    if (!homeOrb || !ringOrb) continue;

    var orbStyle = window.getComputedStyle(homeOrb);
    ringOrb.style.width = orbStyle.width;
    ringOrb.style.height = orbStyle.height;
    ringOrb.style.background = orbStyle.background;
    ringOrb.style.opacity = orbStyle.opacity;
    ringOrb.style.transform = orbStyle.transform;
  }

  ringBg.classList.add('visible');
  return true;
}

function applyAlbumCoverToRing(imgUrl) {
  if (!imgUrl) return;

  var albumBg = document.getElementById('ringBgAlbum');
  var img = new Image();
  img.crossOrigin = 'anonymous';

  img.onload = function() {
    albumBg.style.opacity = '0';
    albumBg.style.backgroundImage = 'url("' + imgUrl + '")';
    albumBg.style.backgroundPosition = 'center';
    albumBg.style.backgroundSize = 'cover';
    albumBg.offsetHeight;
    requestAnimationFrame(function() {
      albumBg.style.opacity = '1';
    });
    extractColorsAndAnimate(imgUrl, 'ringFlowOrb');
  };

  img.onerror = function() {
    albumBg.style.opacity = '0';
    albumBg.style.backgroundImage = 'url("' + imgUrl + '")';
    albumBg.style.backgroundPosition = 'center';
    albumBg.style.backgroundSize = 'cover';
    requestAnimationFrame(function() {
      albumBg.style.opacity = '1';
    });
    extractColorsAndAnimate(imgUrl, 'ringFlowOrb');
  };

  img.src = imgUrl;
}
