// ====== ALARM ACTIONS ======

function enforceSingleAlarmLimit() {
  if (!Array.isArray(alarmRingStore.getAlarms())) {
    alarmRingStore.setAlarms([]);
    return false;
  }

  if (alarmRingStore.getAlarms().length <= 1) return false;

  alarmRingStore.setAlarms([alarmRingStore.getAlarms()[alarmRingStore.getAlarms().length - 1]]);
  return true;
}

function saveAlarm() {
  var data = {
    hour: alarmRingStore.getSelectedHour(),
    minute: alarmRingStore.getSelectedMinute(),
    days: alarmRingStore.getSelectedDays().slice().sort()
  };

  if (alarmRingStore.getEditingAlarmId()) {
    var idx = alarmRingStore.getAlarms().findIndex(function(alarm) {
      return alarm.id === alarmRingStore.getEditingAlarmId();
    });
    if (idx >= 0) {
      alarmRingStore.updateAlarmAt(idx, Object.assign({}, alarmRingStore.getAlarms()[idx], data));
    }
  } else if (alarmRingStore.hasAlarms()) {
    alarmRingStore.setAlarms([Object.assign({}, alarmRingStore.getAlarms()[0], data)]);
  } else {
    alarmRingStore.setAlarms([Object.assign({ id: alarmRingStore.consumeNextAlarmId(), enabled: true }, data)]);
  }

  enforceSingleAlarmLimit();

  storageService.saveAlarms();
  alarmRingStore.clearEditingAlarmId();
  hideSettingOverlay();
  renderHomeScreen();
}

function toggleAlarm(id) {
  var alarm = alarmRingStore.findAlarmById(id);
  if (alarm) alarm.enabled = !alarm.enabled;
  storageService.saveAlarms();
  renderAlarmList();
}

function deleteAlarm(id) {
  alarmRingStore.setAlarms(alarmRingStore.getAlarms().filter(function(alarm) {
    return alarm.id !== id;
  }));
  storageService.saveAlarms();
  renderHomeScreen();
}

function deleteFromSetting() {
  if (alarmRingStore.getEditingAlarmId()) {
    deleteAlarm(alarmRingStore.getEditingAlarmId());
    alarmRingStore.clearEditingAlarmId();
  }
  hideSettingOverlay();
}
