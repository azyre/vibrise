// ====== RING CONTROLLER ======

function resetRingHoldState() {
  ringSession.cancelHold();
}

function resetRingSessionState() {
  ringSession.reset();
}

function testRing() {
  return ringSession.test();
}

function startRingHold() {
  ringSession.startHold();
}

function cancelRingHold() {
  ringSession.cancelHold();
}

function endRingHold() {
  ringSession.endHold();
}

function updateRingClock() {
  ringSession.updateClock();
}

async function previewAlarm(alarm) {
  return ringSession.preview(alarm);
}

async function triggerRing(options) {
  return ringSession.start(options);
}

function bindRingActionZone() {
  ringSession.bindActionZone();
}
