var ringWeatherPort = (function() {
  async function loadCurrentWeather() {
    var loc = await weatherService.getLocation();
    return weatherService.fetchWeather(loc.lat, loc.lon);
  }

  function applyToRing(weather) {
    if (!weather) return;
    applyWeatherToRing(weather);
  }

  return {
    loadCurrentWeather: loadCurrentWeather,
    applyToRing: applyToRing
  };
})();

var ringMusicPort = (function() {
  async function pickSongForRing(weather) {
    return musicSourceService.pickSong(weather);
  }

  return {
    pickSongForRing: pickSongForRing
  };
})();

var ringPlaybackPort = (function() {
  function setCurrentSong(song) {
    alarmRingStore.setCurrentSong(song);
  }

  function getCurrentSong() {
    return alarmRingStore.getCurrentSong();
  }

  function playSong(song) {
    setCurrentSong(song);
    audioService.playSong(song);
  }

  function fadeOutForSnooze(onDone) {
    audioService.fadeOut(350, onDone);
  }

  function resumeAfterSnooze() {
    audioService.resumeWithFade(500);
  }

  function stopSessionPlayback() {
    audioService.stopPlayback();
  }

  return {
    setCurrentSong: setCurrentSong,
    getCurrentSong: getCurrentSong,
    playSong: playSong,
    fadeOutForSnooze: fadeOutForSnooze,
    resumeAfterSnooze: resumeAfterSnooze,
    stopSessionPlayback: stopSessionPlayback
  };
})();
