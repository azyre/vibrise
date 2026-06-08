var alarmScheduler = (function() {
  function check(now) {
    var matchedAlarm = alarmEngine.evaluate(alarmRingStore.getAlarms(), now || new Date());
    if (!matchedAlarm) return;
    alarmTriggerAdapter.dispatch(matchedAlarm);
  }

  function start() {
    if (alarmRingStore.getAlarmCheckInterval()) clearInterval(alarmRingStore.getAlarmCheckInterval());
    alarmRingStore.setAlarmCheckInterval(setInterval(function() {
      check(new Date());
    }, 1000));
  }

  function stop() {
    if (alarmRingStore.getAlarmCheckInterval()) {
      clearInterval(alarmRingStore.getAlarmCheckInterval());
      alarmRingStore.setAlarmCheckInterval(null);
    }
  }

  function reset() {
    alarmEngine.reset();
  }

  return {
    start: start,
    stop: stop,
    checkNow: check,
    reset: reset
  };
})();
