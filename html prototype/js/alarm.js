function startAlarmChecker() {
  alarmScheduler.start();
}

function checkAlarms() {
  alarmScheduler.checkNow(new Date());
}

function stopAlarmChecker() {
  alarmScheduler.stop();
}
