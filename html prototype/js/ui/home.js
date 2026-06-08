// ====== HOME SCREEN ======

var homeClockStarted = false;

function getHomeRenderHandlers() {
  return {
    onOpenAlarm: openAlarmSetting,
    onPreviewAlarm: function(alarm) {
      ringSession.preview(alarm);
    },
    onToggleAlarm: toggleAlarm
  };
}

function getHomeAlarmViewModels() {
  var displayOrder = alarmRingStore.getDisplayOrder();
  var dayShort = alarmRingStore.getHomeAlarmDayShort();

  return alarmRingStore.getSortedAlarms().map(function(alarm) {
    return {
      id: alarm.id,
      enabled: alarm.enabled,
      source: alarm,
      timeText: String(alarm.hour).padStart(2, '0') + ':' + String(alarm.minute).padStart(2, '0'),
      dayLabels: displayOrder.map(function(i) {
        return {
          label: dayShort[i],
          active: alarm.days.includes(i)
        };
      })
    };
  });
}

function getHomeDateText(now) {
  var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return alarmRingStore.getDayLabels()[now.getDay()] + ', ' + months[now.getMonth()] + ' ' + now.getDate();
}

function startHomeClock() {
  if (homeClockStarted) return;

  homeClockStarted = true;
  updateHomeClock();
  setInterval(updateHomeClock, 1000);
  alarmScheduler.start();
  applyWeatherToHome();
}

function renderHomeScreen() {
  homePresenter.renderScreen({
    hasAlarms: alarmRingStore.hasAlarms(),
    alarms: getHomeAlarmViewModels()
  }, getHomeRenderHandlers());
}

function renderAlarmList() {
  homePresenter.renderAlarmList(getHomeAlarmViewModels(), getHomeRenderHandlers());
}

function updateHomeClock() {
  var now = new Date();
  var timeText = String(now.getHours()).padStart(2, '0') + ':' + String(now.getMinutes()).padStart(2, '0');
  homePresenter.updateClock(timeText);
  homePresenter.updateDate(getHomeDateText(now));
}
