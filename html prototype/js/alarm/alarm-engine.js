var alarmEngine = (function() {
  var triggeredKeys = new Set();

  function buildTriggerKey(alarm, hour, minute) {
    return alarm.id + '-' + hour + '-' + minute;
  }

  function clearStaleTriggeredKeys(currentMinute) {
    triggeredKeys.forEach(function(key) {
      var parts = key.split('-');
      var triggeredMinute = parseInt(parts[2], 10);
      if (triggeredMinute !== currentMinute) triggeredKeys.delete(key);
    });
  }

  function evaluate(alarms, now) {
    if (!Array.isArray(alarms) || alarms.length === 0) return null;

    var current = now || new Date();
    var hour = current.getHours();
    var minute = current.getMinutes();
    var day = current.getDay();

    for (var i = 0; i < alarms.length; i++) {
      var alarm = alarms[i];
      var key = buildTriggerKey(alarm, hour, minute);

      if (!triggeredKeys.has(key) && alarmDomain.shouldTriggerAlarmAtTime(alarm, hour, minute, day)) {
        triggeredKeys.add(key);
        return alarm;
      }
    }

    clearStaleTriggeredKeys(minute);
    return null;
  }

  function reset() {
    triggeredKeys.clear();
  }

  return {
    evaluate: evaluate,
    reset: reset
  };
})();
