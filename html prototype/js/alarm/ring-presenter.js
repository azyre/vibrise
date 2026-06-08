var ringPresenter = (function() {
  function getSongTitle(song) {
    return song && song.name ? song.name : 'Unknown Track';
  }

  function getSongArtist(song) {
    if (!song) return 'Unknown Artist';
    return song.artist_name || song.artist || 'Unknown Artist';
  }

  function getSongImage(song) {
    return song && song.image
      ? song.image
      : 'https://placehold.co/400x400/1a1424/f0a050?text=%E2%99%AA';
  }

  function renderDate(now) {
    var weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    var months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    document.getElementById('ringDate').textContent =
      weekdays[now.getDay()] + ' ' + months[now.getMonth()] + ' ' + now.getDate();
  }

  function openSessionView(options) {
    options = options || {};
    layerCoordinator.openRingScreen({ fadeOnly: true });
    syncHomeBackgroundToRing();
    if (options.previewAlarm) {
      showPreviewTime(options.previewAlarm);
      renderDate(new Date());
      return;
    }
    updateClock();
  }

  function closeSessionView() {
    closeTransientOverlays();
    layerCoordinator.closeRingScreen();
    renderHomeScreen();
  }

  function showSongLoading() {
    document.getElementById('albumLoading').style.display = 'flex';
    document.getElementById('albumArt').style.display = 'none';
    document.getElementById('songTitle').textContent = 'Finding music...';
    document.getElementById('songArtist').textContent = 'Loading artist...';
  }

  function setFavoriteSongButtonActive(isFavorited) {
    var btn = document.getElementById('favoriteSongBtn');
    if (!btn) return;
    btn.classList.toggle('active', !!isFavorited);
  }

  function presentSong(song) {
    var art = document.getElementById('albumArt');
    var imgUrl = getSongImage(song);

    document.getElementById('albumLoading').style.display = 'flex';
    art.style.opacity = '0';
    document.getElementById('albumGlow').style.background = 'url(' + imgUrl + ') center/cover';
    applyAlbumCoverToRing(imgUrl);
    document.getElementById('songTitle').textContent = getSongTitle(song);
    document.getElementById('songArtist').textContent = getSongArtist(song);
    setFavoriteSongButtonActive(favoritesStore.isSongFavorited(song));
    prepareShareCard();

    var preloadedArt = new Image();
    preloadedArt.onload = function() {
      document.getElementById('albumLoading').style.display = 'none';
      art.src = imgUrl;
      art.style.display = 'block';
      requestAnimationFrame(function() {
        art.style.opacity = '1';
      });
    };
    preloadedArt.onerror = function() {
      document.getElementById('albumLoading').style.display = 'none';
      art.src = imgUrl;
      art.style.display = 'block';
      requestAnimationFrame(function() {
        art.style.opacity = '1';
      });
    };
    preloadedArt.src = imgUrl;
  }

  function showPreviewTime(alarm) {
    if (!alarm) return;
    document.getElementById('ringTime').textContent =
      String(alarm.hour).padStart(2, '0') + ':' + String(alarm.minute).padStart(2, '0');
  }

  function updateClock(now) {
    var current = now || new Date();
    document.getElementById('ringTime').textContent =
      String(current.getHours()).padStart(2, '0') + ':' + String(current.getMinutes()).padStart(2, '0');
    renderDate(current);
  }

  function showSnoozeCountdown(seconds) {
    document.getElementById('snoozeTimer').textContent =
      Math.floor(seconds / 60) + ':' + String(seconds % 60).padStart(2, '0');
  }

  function openTransientOverlay(overlayId) {
    layerCoordinator.openOverlay(overlayId, 'ringScreen', {
      setDisplay: false,
      hideAfterTransition: false
    });
  }

  function closeTransientOverlay(overlayId) {
    layerCoordinator.closeOverlay(overlayId, 'ringScreen', {
      hideAfterTransition: false
    });
  }

  function closeTransientOverlays() {
    closeTransientOverlay('snoozeOverlay');
    closeTransientOverlay('shareOverlay');
  }

  function restoreHomeBackground(song) {
    var img = song && song.image ? song.image : '';
    if (!img) return;

    var bgBase = document.getElementById('homeBgBase');
    bgBase.style.background = 'url(' + img + ') center/cover';
    bgBase.style.filter = 'blur(50px) brightness(0.35) saturate(1.4)';
    document.getElementById('homeBg').classList.add('visible');
    extractColorsAndAnimate(img);
  }

  function isHomeBackgroundVisible() {
    return document.getElementById('homeBg').classList.contains('visible');
  }

  function bindActionZone(handlers) {
    var actionZone = document.getElementById('ringActionZone');
    if (!actionZone || actionZone.dataset.bound === 'true') return;

    actionZone.dataset.bound = 'true';
    actionZone.addEventListener('mousedown', handlers.onHoldStart);
    actionZone.addEventListener('mouseup', handlers.onHoldEnd);
    actionZone.addEventListener('mouseleave', handlers.onHoldCancel);
    actionZone.addEventListener('touchstart', handlers.onHoldStart, { passive: true });
    actionZone.addEventListener('touchend', handlers.onHoldEnd);
    actionZone.addEventListener('touchcancel', handlers.onHoldCancel);
  }

  function bindSnoozeOverlay(handlers) {
    var cancelBtn = document.getElementById('cancelSnoozeBtn');
    if (!cancelBtn || cancelBtn.dataset.bound === 'true') return;

    cancelBtn.dataset.bound = 'true';
    cancelBtn.addEventListener('click', handlers.onCancelSnooze);
  }

  function bindUI(handlers) {
    bindActionZone(handlers);
    bindSnoozeOverlay(handlers);
  }

  return {
    bindUI: bindUI,
    bindActionZone: bindActionZone,
    bindSnoozeOverlay: bindSnoozeOverlay,
    openSessionView: openSessionView,
    closeSessionView: closeSessionView,
    showSongLoading: showSongLoading,
    setFavoriteSongButtonActive: setFavoriteSongButtonActive,
    presentSong: presentSong,
    showPreviewTime: showPreviewTime,
    updateClock: updateClock,
    showSnoozeCountdown: showSnoozeCountdown,
    openTransientOverlay: openTransientOverlay,
    closeTransientOverlay: closeTransientOverlay,
    closeTransientOverlays: closeTransientOverlays,
    restoreHomeBackground: restoreHomeBackground,
    isHomeBackgroundVisible: isHomeBackgroundVisible
  };
})();
