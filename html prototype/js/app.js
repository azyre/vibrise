// ====== APP HELPERS ======
function renderFavoriteSongButton() {
  var isFavorited = favoritesStore.isSongFavorited(alarmRingStore.getCurrentSong());
  ringPresenter.setFavoriteSongButtonActive(isFavorited);
}

function toggleCurrentSongFavorite() {
  var currentSong = alarmRingStore.getCurrentSong();
  if (!currentSong) return;

  favoritesStore.toggleSong(currentSong);

  storageService.saveFavoriteSongs();
  renderFavoriteSongButton();
  refreshFavoritesScreenIfVisible();
}
