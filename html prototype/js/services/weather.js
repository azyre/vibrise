var weatherService = (function() {
  var weatherMap = {
    0: { name: 'Clear', emoji: '☀️', tag: 'happy', orbColor1: 'rgba(240,180,80,0.35)', orbColor2: 'rgba(255,200,100,0.15)', bgEnd: '#1a1810' },
    1: { name: 'Mostly Clear', emoji: '🌤️', tag: 'happy', orbColor1: 'rgba(200,180,100,0.25)', orbColor2: 'rgba(180,160,100,0.15)', bgEnd: '#181814' },
    2: { name: 'Partly Cloudy', emoji: '⛅', tag: 'lounge+downtempo', orbColor1: 'rgba(150,160,180,0.25)', orbColor2: 'rgba(120,130,160,0.15)', bgEnd: '#141418' },
    3: { name: 'Overcast', emoji: '☁️', tag: 'chillout', orbColor1: 'rgba(130,140,160,0.2)', orbColor2: 'rgba(100,110,130,0.15)', bgEnd: '#12121a' },
    45: { name: 'Foggy', emoji: '🌫️', tag: 'atmospheric', orbColor1: 'rgba(120,120,140,0.2)', orbColor2: 'rgba(100,100,120,0.15)', bgEnd: '#101016' },
    51: { name: 'Light Rain', emoji: '🌦️', tag: 'lofi+chillhop', orbColor1: 'rgba(100,130,200,0.25)', orbColor2: 'rgba(80,100,160,0.15)', bgEnd: '#101420' },
    61: { name: 'Rain', emoji: '🌧️', tag: 'jazz', orbColor1: 'rgba(70,100,180,0.3)', orbColor2: 'rgba(50,80,150,0.2)', bgEnd: '#0a1024' },
    65: { name: 'Heavy Rain', emoji: '🌧️', tag: 'cinematic', orbColor1: 'rgba(60,80,160,0.3)', orbColor2: 'rgba(50,60,130,0.2)', bgEnd: '#080e22' },
    71: { name: 'Light Snow', emoji: '🌨️', tag: 'soft', orbColor1: 'rgba(160,170,200,0.25)', orbColor2: 'rgba(140,150,180,0.15)', bgEnd: '#141620' },
    73: { name: 'Snow', emoji: '❄️', tag: 'newage', orbColor1: 'rgba(170,180,210,0.3)', orbColor2: 'rgba(150,160,190,0.2)', bgEnd: '#141822' },
    95: { name: 'Thunderstorm', emoji: '⛈️', tag: 'epic+adventure', orbColor1: 'rgba(100,60,160,0.3)', orbColor2: 'rgba(60,40,120,0.2)', bgEnd: '#100a22' }
  };

  var accentPool = [
    [255, 100, 150], [100, 255, 180], [255, 200, 50],
    [100, 200, 255], [200, 100, 255], [255, 150, 80],
    [80, 255, 200], [255, 80, 100], [150, 255, 100],
    [180, 120, 255], [255, 180, 200], [120, 220, 160]
  ];

  function getWeatherInfo(code) {
    if (weatherMap[code]) return weatherMap[code];
    if (code >= 0 && code <= 3) return weatherMap[code] || weatherMap[2];
    if (code >= 45 && code <= 48) return weatherMap[45];
    if (code >= 51 && code <= 55) return weatherMap[51];
    if (code >= 56 && code <= 65) return weatherMap[61];
    if (code >= 71 && code <= 75) return weatherMap[73];
    if (code >= 95) return weatherMap[95];
    if (code >= 80) return weatherMap[61];
    return weatherMap[2];
  }

  async function fetchWeather(lat, lon) {
    var now = Date.now();
    if (
      state.cache.cachedWeather &&
      state.cache.cachedWeatherAt &&
      now - state.cache.cachedWeatherAt < 10 * 60 * 1000
    ) {
      return state.cache.cachedWeather;
    }
    try {
      var res = await fetch('https://api.open-meteo.com/v1/forecast?latitude=' + lat + '&longitude=' + lon + '&current_weather=true');
      state.cache.cachedWeather = (await res.json()).current_weather;
      state.cache.cachedWeatherAt = now;
      return state.cache.cachedWeather;
    } catch (e) { return state.cache.cachedWeather || null; }
  }

  async function getLocation() {
    if (state.cache.cachedLocation) return state.cache.cachedLocation;
    return new Promise(function(resolve) {
      if (!navigator.geolocation) {
        state.cache.cachedLocation = { lat: 39.9, lon: 116.4 };
        resolve(state.cache.cachedLocation);
        return;
      }
      navigator.geolocation.getCurrentPosition(
        function(pos) {
          state.cache.cachedLocation = { lat: pos.coords.latitude, lon: pos.coords.longitude };
          resolve(state.cache.cachedLocation);
        },
        function() {
          state.cache.cachedLocation = { lat: 39.9, lon: 116.4 };
          resolve(state.cache.cachedLocation);
        },
        { timeout: 5000 }
      );
    });
  }

  function generateWeatherStyle(code, temp) {
    var t = temp ?? 20;

    if (code >= 95) return {
      bg: 'radial-gradient(ellipse at 20% 30%, rgba(120,50,180,0.5) 0%, transparent 50%),' +
          'radial-gradient(ellipse at 80% 70%, rgba(50,30,140,0.4) 0%, transparent 50%),' +
          'radial-gradient(circle at 60% 15%, rgba(200,180,255,0.12) 0%, transparent 30%),' +
          'linear-gradient(180deg, #08061a 0%, #150a28 50%, #0a0614 100%)',
      colors: [[120,50,180],[50,30,140],[90,40,160],[150,100,200]]
    };

    if (code >= 71 && code <= 77) return {
      bg: 'radial-gradient(ellipse at 30% 20%, rgba(180,195,220,0.4) 0%, transparent 55%),' +
          'radial-gradient(ellipse at 70% 75%, rgba(150,165,200,0.3) 0%, transparent 50%),' +
          'radial-gradient(circle at 50% 50%, rgba(200,210,230,0.15) 0%, transparent 60%),' +
          'linear-gradient(180deg, #0e1018 0%, #141822 50%, #0c0e16 100%)',
      colors: [[180,195,220],[150,165,200],[170,180,210],[200,210,230]]
    };

    if (code >= 61) return {
      bg: 'radial-gradient(ellipse at 25% 35%, rgba(50,80,160,0.45) 0%, transparent 50%),' +
          'radial-gradient(ellipse at 75% 65%, rgba(40,60,130,0.35) 0%, transparent 50%),' +
          'radial-gradient(circle at 40% 80%, rgba(70,100,180,0.2) 0%, transparent 45%),' +
          'linear-gradient(180deg, #080c1a 0%, #0a1028 50%, #060a16 100%)',
      colors: [[50,80,160],[40,60,130],[70,100,180],[60,90,150]]
    };

    if (code >= 51) return {
      bg: 'radial-gradient(ellipse at 30% 25%, rgba(100,130,200,0.35) 0%, transparent 55%),' +
          'radial-gradient(ellipse at 65% 70%, rgba(80,110,170,0.25) 0%, transparent 50%),' +
          'radial-gradient(circle at 50% 45%, rgba(130,150,200,0.15) 0%, transparent 55%),' +
          'linear-gradient(180deg, #0a0e1a 0%, #101420 50%, #0a0c18 100%)',
      colors: [[100,130,200],[80,110,170],[90,120,185],[120,145,210]]
    };

    if (code >= 45 && code <= 48) return {
      bg: 'radial-gradient(ellipse at 35% 30%, rgba(120,130,145,0.35) 0%, transparent 55%),' +
          'radial-gradient(ellipse at 65% 65%, rgba(100,115,130,0.25) 0%, transparent 55%),' +
          'radial-gradient(circle at 50% 50%, rgba(140,145,155,0.12) 0%, transparent 60%),' +
          'linear-gradient(180deg, #0c0c12 0%, #101016 50%, #0a0a10 100%)',
      colors: [[120,130,145],[100,115,130],[110,122,137],[135,140,155]]
    };

    if (code >= 2 && code <= 3) return {
      bg: 'radial-gradient(ellipse at 30% 25%, rgba(140,150,175,0.3) 0%, transparent 55%),' +
          'radial-gradient(ellipse at 70% 70%, rgba(115,125,150,0.25) 0%, transparent 50%),' +
          'radial-gradient(circle at 50% 45%, rgba(160,165,180,0.1) 0%, transparent 55%),' +
          'linear-gradient(180deg, #0c0e14 0%, #12141a 50%, #0a0c12 100%)',
      colors: [[140,150,175],[115,125,150],[130,140,165],[155,160,180]]
    };

    if (t >= 30) return {
      bg: 'radial-gradient(ellipse at 30% 25%, rgba(255,140,40,0.45) 0%, transparent 50%),' +
          'radial-gradient(ellipse at 70% 70%, rgba(220,80,30,0.3) 0%, transparent 50%),' +
          'radial-gradient(circle at 50% 10%, rgba(255,180,80,0.2) 0%, transparent 40%),' +
          'linear-gradient(180deg, #1a1208 0%, #1c1410 50%, #140e08 100%)',
      colors: [[255,140,40],[220,80,30],[240,110,35],[255,180,80]]
    };

    if (t >= 20) return {
      bg: 'radial-gradient(ellipse at 25% 30%, rgba(240,180,80,0.4) 0%, transparent 55%),' +
          'radial-gradient(ellipse at 75% 65%, rgba(200,150,60,0.3) 0%, transparent 50%),' +
          'radial-gradient(circle at 55% 20%, rgba(255,200,100,0.15) 0%, transparent 45%),' +
          'linear-gradient(180deg, #141008 0%, #1a1810 50%, #120e08 100%)',
      colors: [[240,180,80],[200,150,60],[220,165,70],[255,200,100]]
    };

    if (t >= 10) return {
      bg: 'radial-gradient(ellipse at 30% 25%, rgba(100,180,200,0.35) 0%, transparent 55%),' +
          'radial-gradient(ellipse at 70% 70%, rgba(80,150,180,0.25) 0%, transparent 50%),' +
          'radial-gradient(circle at 45% 15%, rgba(120,200,220,0.15) 0%, transparent 45%),' +
          'linear-gradient(180deg, #0a1014 0%, #0e1618 50%, #080e12 100%)',
      colors: [[100,180,200],[80,150,180],[90,165,190],[120,200,220]]
    };

    if (t >= 0) return {
      bg: 'radial-gradient(ellipse at 25% 30%, rgba(80,120,190,0.35) 0%, transparent 55%),' +
          'radial-gradient(ellipse at 70% 65%, rgba(60,100,170,0.25) 0%, transparent 50%),' +
          'radial-gradient(circle at 50% 20%, rgba(100,140,200,0.15) 0%, transparent 45%),' +
          'linear-gradient(180deg, #080c16 0%, #0e1420 50%, #080a14 100%)',
      colors: [[80,120,190],[60,100,170],[70,110,180],[100,140,200]]
    };

    return {
      bg: 'radial-gradient(ellipse at 30% 25%, rgba(160,180,220,0.35) 0%, transparent 55%),' +
          'radial-gradient(ellipse at 65% 70%, rgba(140,160,210,0.3) 0%, transparent 50%),' +
          'radial-gradient(circle at 50% 40%, rgba(180,200,235,0.15) 0%, transparent 55%),' +
          'linear-gradient(180deg, #0c0e18 0%, #101420 50%, #0a0c16 100%)',
      colors: [[160,180,220],[140,160,210],[150,170,215],[180,200,235]]
    };
  }

  function spiceUpStyle(style) {
    var count = 2 + Math.floor(Math.random() * 2);
    var picked = [];
    var used = new Set();
    while (picked.length < count) {
      var idx = Math.floor(Math.random() * accentPool.length);
      if (!used.has(idx)) {
        used.add(idx);
        picked.push(accentPool[idx]);
      }
    }

    var rx = function() { return 10 + Math.floor(Math.random() * 80); };
    var ro = function() { return (0.05 + Math.random() * 0.07).toFixed(2); };
    var sizes = [20, 30, 45, 60, 75];

    var layers = picked.map(function(color) {
      var size = sizes[Math.floor(Math.random() * sizes.length)];
      var shape = Math.random() > 0.5 ? 'ellipse' : 'circle';
      return 'radial-gradient(' + shape + ' at ' + rx() + '% ' + rx() + '%, rgba(' + color + ',' + ro() + ') 0%, transparent ' + size + '%)';
    });

    style.bg = layers.join(',\n') + ',\n' + style.bg;
    picked.forEach(function(color) { style.colors.push(color); });
  }

  function getDaylightFactor() {
    var now = new Date();
    var h = now.getHours() + now.getMinutes() / 60;
    return 0.5 + 0.5 * Math.cos((h - 12) * Math.PI / 12);
  }

  return {
    getWeatherInfo: getWeatherInfo,
    fetchWeather: fetchWeather,
    getLocation: getLocation,
    generateWeatherStyle: generateWeatherStyle,
    spiceUpStyle: spiceUpStyle,
    getDaylightFactor: getDaylightFactor
  };
})();
