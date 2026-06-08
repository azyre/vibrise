var alarmTriggerAdapter = (function() {
  function dispatch(alarm) {
    if (!alarm) return;

    if (alarm.days.length === 0) deleteAlarm(alarm.id);

    ringSession.start({
      alarm: alarm,
      source: 'schedule'
    });
  }

  return {
    dispatch: dispatch
  };
})();
