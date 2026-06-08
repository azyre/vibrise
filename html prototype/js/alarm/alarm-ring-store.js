var alarmRingStore = (function() {
  function getAlarms() {
    return state.alarm.alarms;
  }

  function setAlarms(alarms) {
    state.alarm.alarms = alarms;
  }

  function hasAlarms() {
    return state.alarm.alarms.length > 0;
  }

  function findAlarmById(id) {
    return state.alarm.alarms.find(function(alarm) {
      return alarm.id === id;
    }) || null;
  }

  function updateAlarmAt(index, alarm) {
    state.alarm.alarms[index] = alarm;
  }

  function getEditingAlarmId() {
    return state.alarm.editingAlarmId;
  }

  function setEditingAlarmId(alarmId) {
    state.alarm.editingAlarmId = alarmId;
  }

  function clearEditingAlarmId() {
    state.alarm.editingAlarmId = null;
  }

  function getSelectedHour() {
    return state.alarm.selectedHour;
  }

  function setSelectedHour(hour) {
    state.alarm.selectedHour = hour;
  }

  function getSelectedMinute() {
    return state.alarm.selectedMinute;
  }

  function setSelectedMinute(minute) {
    state.alarm.selectedMinute = minute;
  }

  function getSelectedDays() {
    return state.alarm.selectedDays;
  }

  function setSelectedDays(days) {
    state.alarm.selectedDays = days;
  }

  function resetAlarmSelection() {
    state.alarm.selectedHour = 7;
    state.alarm.selectedMinute = 0;
    state.alarm.selectedDays = [1, 2, 3, 4, 5];
  }

  function getNextAlarmId() {
    return state.alarm.nextAlarmId;
  }

  function setNextAlarmId(nextAlarmId) {
    state.alarm.nextAlarmId = nextAlarmId;
  }

  function consumeNextAlarmId() {
    return state.alarm.nextAlarmId++;
  }

  function getDisplayOrder() {
    return state.constants.DISPLAY_ORDER;
  }

  function getDayLabelsShort() {
    return state.constants.DAY_LABELS_SHORT;
  }

  function getDayLabels() {
    return state.constants.DAY_LABELS;
  }

  function getHomeAlarmDayShort() {
    return ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  }

  function getSortedAlarms() {
    return state.alarm.alarms.slice().sort(function(a, b) {
      return a.hour * 60 + a.minute - (b.hour * 60 + b.minute);
    });
  }

  function getAlarmCheckInterval() {
    return state.timers.alarmCheckInterval;
  }

  function setAlarmCheckInterval(intervalId) {
    state.timers.alarmCheckInterval = intervalId;
  }

  function getRingClockInterval() {
    return state.timers.ringClockInterval;
  }

  function setRingClockInterval(intervalId) {
    state.timers.ringClockInterval = intervalId;
  }

  function getSnoozeCountdownTimer() {
    return state.timers.snoozeCountdown;
  }

  function setSnoozeCountdownTimer(intervalId) {
    state.timers.snoozeCountdown = intervalId;
  }

  function getCurrentSong() {
    return state.playback.currentSong;
  }

  function setCurrentSong(song) {
    state.playback.currentSong = song;
  }

  function getHoldTimer() {
    return state.ring.holdTimer;
  }

  function setHoldTimer(timerId) {
    state.ring.holdTimer = timerId;
  }

  function isHoldTriggered() {
    return state.ring.holdTriggered;
  }

  function setHoldTriggered(value) {
    state.ring.holdTriggered = !!value;
  }

  function getSnoozeRemainingSeconds() {
    return state.ring.snoozeRemainingSeconds;
  }

  function setSnoozeRemainingSeconds(value) {
    state.ring.snoozeRemainingSeconds = value;
  }

  function decrementSnoozeRemainingSeconds() {
    state.ring.snoozeRemainingSeconds -= 1;
    return state.ring.snoozeRemainingSeconds;
  }

  function startRingSession(options) {
    options = options || {};
    state.ring.activeAlarmId = options.alarm && options.alarm.id ? options.alarm.id : null;
    state.ring.isPreview = !!options.preview;
    state.ring.source = options.source || null;
  }

  function resetRingSession() {
    state.ring.activeAlarmId = null;
    state.ring.isPreview = false;
    state.ring.source = null;
  }

  return {
    getAlarms: getAlarms,
    setAlarms: setAlarms,
    hasAlarms: hasAlarms,
    findAlarmById: findAlarmById,
    updateAlarmAt: updateAlarmAt,
    getEditingAlarmId: getEditingAlarmId,
    setEditingAlarmId: setEditingAlarmId,
    clearEditingAlarmId: clearEditingAlarmId,
    getSelectedHour: getSelectedHour,
    setSelectedHour: setSelectedHour,
    getSelectedMinute: getSelectedMinute,
    setSelectedMinute: setSelectedMinute,
    getSelectedDays: getSelectedDays,
    setSelectedDays: setSelectedDays,
    resetAlarmSelection: resetAlarmSelection,
    getNextAlarmId: getNextAlarmId,
    setNextAlarmId: setNextAlarmId,
    consumeNextAlarmId: consumeNextAlarmId,
    getDisplayOrder: getDisplayOrder,
    getDayLabelsShort: getDayLabelsShort,
    getDayLabels: getDayLabels,
    getHomeAlarmDayShort: getHomeAlarmDayShort,
    getSortedAlarms: getSortedAlarms,
    getAlarmCheckInterval: getAlarmCheckInterval,
    setAlarmCheckInterval: setAlarmCheckInterval,
    getRingClockInterval: getRingClockInterval,
    setRingClockInterval: setRingClockInterval,
    getSnoozeCountdownTimer: getSnoozeCountdownTimer,
    setSnoozeCountdownTimer: setSnoozeCountdownTimer,
    getCurrentSong: getCurrentSong,
    setCurrentSong: setCurrentSong,
    getHoldTimer: getHoldTimer,
    setHoldTimer: setHoldTimer,
    isHoldTriggered: isHoldTriggered,
    setHoldTriggered: setHoldTriggered,
    getSnoozeRemainingSeconds: getSnoozeRemainingSeconds,
    setSnoozeRemainingSeconds: setSnoozeRemainingSeconds,
    decrementSnoozeRemainingSeconds: decrementSnoozeRemainingSeconds,
    startRingSession: startRingSession,
    resetRingSession: resetRingSession
  };
})();
