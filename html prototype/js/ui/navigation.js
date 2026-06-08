// ====== SCREEN NAVIGATION ======

function showScreen(id) {
  layerCoordinator.showScreen(id, {
    onShow: function() {
      if (id === 'homeScreen') renderHomeScreen();
    }
  });
}

function openScaledOverlay(overlayId, underlayId, options) {
  layerCoordinator.openOverlay(overlayId, underlayId, options);
}

function closeScaledOverlay(overlayId, underlayId, options) {
  layerCoordinator.closeOverlay(overlayId, underlayId, options);
}

function openRingScreen(options) {
  layerCoordinator.openRingScreen(options);
}

function closeRingScreen() {
  layerCoordinator.closeRingScreen();
}
