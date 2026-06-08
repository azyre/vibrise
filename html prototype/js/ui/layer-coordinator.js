var layerCoordinator = (function() {
  var overlayTransitionMs = 400;
  var ringScreenTransitionMs = 400;
  var ringScreenHideTimer = null;

  function getLayerPair(primaryId, secondaryId) {
    var primary = document.getElementById(primaryId);
    var secondary = document.getElementById(secondaryId);
    if (!primary || !secondary) return null;

    return {
      primary: primary,
      secondary: secondary
    };
  }

  function clearHideTimer(layer) {
    if (layer && layer._hideTimer) {
      clearTimeout(layer._hideTimer);
      layer._hideTimer = null;
    }
  }

  function showScreen(screenId, options) {
    options = options || {};

    document.querySelectorAll('.screen').forEach(function(screen) {
      screen.classList.add('hidden');
    });

    var screen = document.getElementById(screenId);
    if (!screen) return;

    screen.classList.remove('hidden');

    if (typeof options.onShow === 'function') {
      options.onShow(screen);
    }
  }

  function openOverlay(overlayId, underlayId, options) {
    options = options || {};
    var pair = getLayerPair(overlayId, underlayId);
    if (!pair) return;

    var overlay = pair.primary;
    var underlay = pair.secondary;

    clearHideTimer(overlay);

    if (options.setDisplay !== false) {
      overlay.style.display = options.displayValue || 'flex';
    }

    requestAnimationFrame(function() {
      underlay.classList.add(options.underlayClass || 'underlay-scaled');
      overlay.classList.add(options.visibleClass || 'visible');
    });
  }

  function closeOverlay(overlayId, underlayId, options) {
    options = options || {};
    var pair = getLayerPair(overlayId, underlayId);
    if (!pair) return;

    var overlay = pair.primary;
    var underlay = pair.secondary;

    overlay.classList.remove(options.visibleClass || 'visible');
    underlay.classList.remove(options.underlayClass || 'underlay-scaled');

    if (options.hideAfterTransition === false) return;

    clearHideTimer(overlay);
    overlay._hideTimer = setTimeout(function() {
      if (!overlay.classList.contains(options.visibleClass || 'visible')) {
        overlay.style.display = 'none';
      }
      overlay._hideTimer = null;
    }, options.transitionMs || overlayTransitionMs);
  }

  function openRingScreen(options) {
    options = options || {};
    var pair = getLayerPair('ringScreen', 'homeScreen');
    if (!pair) return;

    var ringScreen = pair.primary;
    var homeScreen = pair.secondary;

    if (ringScreenHideTimer) {
      clearTimeout(ringScreenHideTimer);
      ringScreenHideTimer = null;
    }

    homeScreen.classList.remove('underlay-scaled');
    homeScreen.classList.remove('underlay-faded');
    ringScreen.classList.toggle('fade-only', !!options.fadeOnly);
    ringScreen.classList.remove('hidden');

    requestAnimationFrame(function() {
      homeScreen.classList.add(options.fadeOnly ? 'underlay-faded' : 'underlay-scaled');
      ringScreen.classList.add('visible');
    });
  }

  function closeRingScreen() {
    var pair = getLayerPair('ringScreen', 'homeScreen');
    if (!pair) return;

    var ringScreen = pair.primary;
    var homeScreen = pair.secondary;

    ringScreen.classList.remove('visible');
    homeScreen.classList.remove('underlay-scaled');
    homeScreen.classList.remove('underlay-faded');

    if (ringScreenHideTimer) clearTimeout(ringScreenHideTimer);
    ringScreenHideTimer = setTimeout(function() {
      if (!ringScreen.classList.contains('visible')) {
        ringScreen.classList.add('hidden');
        ringScreen.classList.remove('fade-only');
      }
    }, ringScreenTransitionMs);
  }

  function isLayerVisible(layerId, options) {
    options = options || {};
    var layer = document.getElementById(layerId);
    if (!layer) return false;
    return layer.classList.contains(options.visibleClass || 'visible');
  }

  return {
    showScreen: showScreen,
    openOverlay: openOverlay,
    closeOverlay: closeOverlay,
    openRingScreen: openRingScreen,
    closeRingScreen: closeRingScreen,
    isLayerVisible: isLayerVisible
  };
})();
