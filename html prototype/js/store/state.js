var state = {
  config: {
    JAMENDO_CLIENT_ID: '8e61e407',
    IS_DEMO: false
  },
  playback: {
    currentSong: null,
    audioPlayer: null,
    volumeInterval: null
  },
  timers: {
    snoozeCountdown: null,
    alarmCheckInterval: null,
    ringClockInterval: null
  },
  cache: {
    cachedLocation: null,
    cachedWeather: null,
    cachedWeatherAt: 0
  },
  alarm: {
    alarms: [],
    nextAlarmId: 1,
    editingAlarmId: null,
    selectedHour: 7,
    selectedMinute: 0,
    selectedDays: []
  },
  ring: {
    activeAlarmId: null,
    isPreview: false,
    source: null,
    holdTimer: null,
    holdTriggered: false,
    snoozeRemainingSeconds: 0
  },
  favorites: {
    favoriteSongs: []
  },
  constants: {
    DAY_LABELS: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    DAY_LABELS_SHORT: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    DISPLAY_ORDER: [1, 2, 3, 4, 5, 6, 0]
  }
};
