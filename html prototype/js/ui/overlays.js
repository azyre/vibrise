// ====== SNOOZE & DISMISS ======

function snooze() {
  return ringSession.snooze();
}

function cancelSnooze() {
  return ringSession.cancelSnooze();
}

function dismiss() {
  return ringSession.dismiss();
}

function bindSnoozeOverlayActions() {
  ringSession.bindSnoozeOverlayActions();
}
