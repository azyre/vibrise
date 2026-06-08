var ringSession = (function() {
  var HOLD_DELAY_MS = 550;
  var SNOOZE_DURATION_SECONDS = 300;

  function clearHoldTimer() {
    if (alarmRingStore.getHoldTimer()) {
      clearTimeout(alarmRingStore.getHoldTimer());
      alarmRingStore.setHoldTimer(null);
    }
  }

  function resetHoldState() {
    clearHoldTimer();
    alarmRingStore.setHoldTriggered(false);
  }

  function stopClock() {
    if (alarmRingStore.getRingClockInterval()) {
      clearInterval(alarmRingStore.getRingClockInterval());
      alarmRingStore.setRingClockInterval(null);
    }
  }

  function clearSnoozeCountdown() {
    if (alarmRingStore.getSnoozeCountdownTimer()) {
      clearInterval(alarmRingStore.getSnoozeCountdownTimer());
      alarmRingStore.setSnoozeCountdownTimer(null);
    }
    alarmRingStore.setSnoozeRemainingSeconds(0);
  }

  function resetState() {
    stopClock();
    clearSnoozeCountdown();
    resetHoldState();
    alarmRingStore.resetRingSession();
  }

  async function loadAndPlaySong(weather) {
    ringPresenter.showSongLoading();
    var song = await ringMusicPort.pickSongForRing(weather);
    if (!song) return;
    ringPresenter.presentSong(song);
    ringPlaybackPort.playSong(song);
  }

  function updateClock() {
    ringPresenter.updateClock(new Date());
  }

  function syncClock(options) {
    options = options || {};

    stopClock();
    if (options.previewAlarm) {
      ringPresenter.showPreviewTime(options.previewAlarm);
      ringPresenter.updateClock(new Date());
    } else {
      updateClock();
    }

    alarmRingStore.setRingClockInterval(setInterval(updateClock, 1000));
  }

  function resumeFromSnooze() {
    ringPresenter.closeTransientOverlay('snoozeOverlay');
    ringPlaybackPort.resumeAfterSnooze();
  }

  function startSnoozeCountdown(durationSeconds) {
    clearSnoozeCountdown();
    alarmRingStore.setSnoozeRemainingSeconds(durationSeconds);
    ringPresenter.showSnoozeCountdown(alarmRingStore.getSnoozeRemainingSeconds());

    alarmRingStore.setSnoozeCountdownTimer(setInterval(function() {
      var remaining = alarmRingStore.decrementSnoozeRemainingSeconds();
      ringPresenter.showSnoozeCountdown(remaining);

      if (remaining <= 0) {
        clearSnoozeCountdown();
        resumeFromSnooze();
      }
    }, 1000));
  }

  async function begin(options) {
    options = options || {};

    alarmRingStore.startRingSession({
      alarm: options.alarm,
      preview: options.preview,
      source: options.source
    });
    resetHoldState();
    clearSnoozeCountdown();

    ringPresenter.openSessionView({
      previewAlarm: options.preview ? options.alarm : null
    });
    syncClock({
      previewAlarm: options.preview ? options.alarm : null
    });

    var weather = await ringWeatherPort.loadCurrentWeather();
    if (!ringPresenter.isHomeBackgroundVisible()) {
      ringWeatherPort.applyToRing(weather);
    }
    await loadAndPlaySong(weather);
  }

  function start(options) {
    options = options || {};
    return begin({
      alarm: options.alarm || null,
      preview: false,
      source: options.source || 'schedule'
    });
  }

  function preview(alarm) {
    return begin({
      alarm: alarm,
      preview: true,
      source: 'preview'
    });
  }

  function test() {
    return start({ source: 'manual' });
  }

  function snooze() {
    resetHoldState();
    ringPlaybackPort.fadeOutForSnooze(function() {
      ringPresenter.openTransientOverlay('snoozeOverlay');
      startSnoozeCountdown(SNOOZE_DURATION_SECONDS);
    });
  }

  function cancelSnooze() {
    clearSnoozeCountdown();
    resumeFromSnooze();
  }

  function dismiss() {
    ringPlaybackPort.stopSessionPlayback();
    ringPresenter.restoreHomeBackground(ringPlaybackPort.getCurrentSong());
    resetState();
    ringPresenter.closeSessionView();
  }

  function startHold() {
    clearHoldTimer();
    alarmRingStore.setHoldTriggered(false);
    alarmRingStore.setHoldTimer(setTimeout(function() {
      alarmRingStore.setHoldTriggered(true);
      dismiss();
    }, HOLD_DELAY_MS));
  }

  function cancelHold() {
    resetHoldState();
  }

  function endHold() {
    if (alarmRingStore.isHoldTriggered()) {
      resetHoldState();
      return;
    }

    resetHoldState();
    snooze();
  }

  function bindActionZone() {
    ringPresenter.bindActionZone({
      onHoldStart: startHold,
      onHoldEnd: endHold,
      onHoldCancel: cancelHold
    });
  }

  function bindSnoozeOverlayActions() {
    ringPresenter.bindSnoozeOverlay({
      onCancelSnooze: cancelSnooze
    });
  }

  function bindUI() {
    ringPresenter.bindUI({
      onHoldStart: startHold,
      onHoldEnd: endHold,
      onHoldCancel: cancelHold,
      onCancelSnooze: cancelSnooze
    });
  }

  return {
    bindUI: bindUI,
    bindActionZone: bindActionZone,
    bindSnoozeOverlayActions: bindSnoozeOverlayActions,
    start: start,
    preview: preview,
    test: test,
    snooze: snooze,
    cancelSnooze: cancelSnooze,
    dismiss: dismiss,
    startHold: startHold,
    endHold: endHold,
    cancelHold: cancelHold,
    updateClock: updateClock,
    reset: resetState
  };
})();
