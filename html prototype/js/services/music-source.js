var musicSourceService = (function() {
  var demoSongs = [
    { name: 'Morning Light', artist: 'Daydrift', image: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=400&h=400&fit=crop', audio: '', duration: 195 },
    { name: 'Rainy Thoughts', artist: 'Cloud Harbor', image: 'https://images.unsplash.com/photo-1501908734255-16579c18c25f?w=400&h=400&fit=crop', audio: '', duration: 220 },
    { name: 'Gentle Awakening', artist: 'Soft Parade', image: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400&h=400&fit=crop', audio: '', duration: 180 },
    { name: 'Winter Silence', artist: 'North Static', image: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&h=400&fit=crop', audio: '', duration: 240 },
    { name: 'Electric Sunrise', artist: 'Signal Bloom', image: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop', audio: '', duration: 200 },
    { name: 'Forest Walk', artist: 'Moss Avenue', image: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=400&fit=crop', audio: '', duration: 210 }
  ];

  function getBaseJamendoParams() {
    return {
      client_id: state.config.JAMENDO_CLIENT_ID,
      format: 'json',
      limit: '1',
      vocalinstrumental: 'instrumental',
      durationbetween: '60_600',
      audioformat: 'mp32',
      imagesize: '400',
      include: 'musicinfo'
    };
  }

  function buildFilterParams(tag, speed) {
    var filterParams = {};
    if (tag) filterParams.fuzzytags = tag;
    if (speed) filterParams.speed = speed;
    return filterParams;
  }

  function normalizeFullCount(data) {
    var total = Number(data && data.headers && data.headers.results_fullcount);
    return isNaN(total) ? 0 : total;
  }

  function getRandomOffset(total) {
    return String(Math.floor(Math.random() * Math.max(1, Math.min(total || 0, 500))));
  }

  async function searchJamendo(params) {
    try {
      var query = new URLSearchParams(Object.assign(getBaseJamendoParams(), params));
      var data = await (await fetch('https://api.jamendo.com/v3.0/tracks/?' + query)).json();
      return data.results && data.results[0] ? data.results[0] : null;
    } catch (e) { return null; }
  }

  async function getFullCount(params) {
    try {
      var query = new URLSearchParams(Object.assign(getBaseJamendoParams(), {
        fullcount: 'true'
      }, params));
      var data = await (await fetch('https://api.jamendo.com/v3.0/tracks/?' + query)).json();
      return normalizeFullCount(data);
    } catch (e) { return 0; }
  }

  async function fetchRandomSong(tag, speed) {
    try {
      var fullFilterParams = buildFilterParams(tag, speed);
      var total = await getFullCount(fullFilterParams);

      if (total >= 100) {
        var fullFilterSong = await searchJamendo(Object.assign({}, fullFilterParams, {
          offset: getRandomOffset(total)
        }));
        if (fullFilterSong) return fullFilterSong;
      }

      if (tag) {
        var tagOnlyParams = buildFilterParams(tag, '');
        var tagOnlyTotal = await getFullCount(tagOnlyParams);

        if (tagOnlyTotal >= 100) {
          var tagOnlySong = await searchJamendo(Object.assign({}, tagOnlyParams, {
            offset: getRandomOffset(tagOnlyTotal)
          }));
          if (tagOnlySong) return tagOnlySong;
        }
      }

      return await searchJamendo({ offset: getRandomOffset(500) });
    } catch (e) { return null; }
  }

  async function pickSong(weather) {
    var now = new Date();
    var songProfile = musicSelectionDomain.resolveSongProfile(weather, now, weatherService.getWeatherInfo);
    var tag = songProfile.tag;
    var speed = songProfile.speed;

    var song = null;
    if (!state.config.IS_DEMO) song = await fetchRandomSong(tag, speed);
    if (!song) song = Object.assign({}, demoSongs[Math.floor(Math.random() * demoSongs.length)]);
    return song;
  }

  return {
    searchJamendo: searchJamendo,
    getFullCount: getFullCount,
    fetchRandomSong: fetchRandomSong,
    pickSong: pickSong
  };
})();
