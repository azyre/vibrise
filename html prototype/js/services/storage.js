var storageService = {
  saveAlarms: function() {
    try {
      localStorage.setItem('vibrise_alarms', JSON.stringify(alarmRingStore.getAlarms()));
      localStorage.setItem('vibrise_nextId', String(alarmRingStore.getNextAlarmId()));
    } catch (e) {}
  },

  loadAlarms: function() {
    var alarms = [];
    var nextId = 1;

    try {
      var saved = localStorage.getItem('vibrise_alarms');
      if (saved) alarms = JSON.parse(saved);

      var savedId = localStorage.getItem('vibrise_nextId');
      if (savedId) nextId = parseInt(savedId, 10);
    } catch (e) {}

    if (!Array.isArray(alarms)) alarms = [];
    if (isNaN(nextId) || nextId < 1) nextId = 1;

    alarmRingStore.setAlarms(alarms);
    alarmRingStore.setNextAlarmId(nextId);
  },

  saveFavoriteSongs: function() {
    try {
      localStorage.setItem(
        'vibrise_favorite_songs',
        JSON.stringify(favoritesStore.getFavoriteSongs())
      );
    } catch (e) {}
  },

  loadFavoriteSongs: function() {
    try {
      var saved = localStorage.getItem('vibrise_favorite_songs');
      if (saved) favoritesStore.setFavoriteSongs(JSON.parse(saved));
    } catch (e) {}

    if (!Array.isArray(favoritesStore.getFavoriteSongs())) favoritesStore.setFavoriteSongs([]);
  }
};
