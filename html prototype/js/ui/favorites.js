// ====== FAVORITES ======

function syncHomeBackgroundToFavorites() {
  return;
}

function getFavoritesScreenModel() {
  return {
    hasSongs: favoritesStore.hasFavoriteSongs(),
    songs: favoritesStore.getFavoriteSongsNewestFirst().map(function(song) {
      return {
        title: song.name || 'Unknown Track',
        artist: song.artist || 'Unknown Artist',
        image: song.image || 'https://placehold.co/120x120/221b17/ffffff?text=%E2%99%AA'
      };
    })
  };
}

function renderFavoritesScreen() {
  favoritesPresenter.renderScreen(getFavoritesScreenModel());
}

function isFavoritesScreenVisible() {
  return layerCoordinator.isLayerVisible('favoritesScreen');
}

function refreshFavoritesScreenIfVisible() {
  if (isFavoritesScreenVisible()) renderFavoritesScreen();
}

function openFavoritesScreen() {
  syncHomeBackgroundToFavorites();
  renderFavoritesScreen();
  layerCoordinator.openOverlay('favoritesScreen', 'homeScreen');
}

function closeFavoritesScreen() {
  layerCoordinator.closeOverlay('favoritesScreen', 'homeScreen');
}
