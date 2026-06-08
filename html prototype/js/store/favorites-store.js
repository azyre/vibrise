var favoritesStore = (function() {
  function getFavoriteSongs() {
    return state.favorites.favoriteSongs;
  }

  function setFavoriteSongs(songs) {
    state.favorites.favoriteSongs = Array.isArray(songs) ? songs : [];
  }

  function hasFavoriteSongs() {
    return state.favorites.favoriteSongs.length > 0;
  }

  function getFavoriteSongsNewestFirst() {
    return state.favorites.favoriteSongs.slice().reverse();
  }

  function isSongFavorited(song) {
    return favoritesDomain.isSongFavorited(song, state.favorites.favoriteSongs);
  }

  function findFavoriteIndexByKey(key) {
    return state.favorites.favoriteSongs.findIndex(function(savedSong) {
      return savedSong.key === key;
    });
  }

  function createSavedFavoriteSong(song) {
    return {
      key: favoritesDomain.getSongFavoriteKey(song),
      name: song.name || 'Unknown Track',
      artist: song.artist_name || song.artist || 'Unknown Artist',
      image: song.image || ''
    };
  }

  function toggleSong(song) {
    var key = favoritesDomain.getSongFavoriteKey(song);
    var existingIndex = findFavoriteIndexByKey(key);

    if (existingIndex >= 0) {
      state.favorites.favoriteSongs.splice(existingIndex, 1);
      return false;
    }

    state.favorites.favoriteSongs.push(createSavedFavoriteSong(song));
    return true;
  }

  return {
    getFavoriteSongs: getFavoriteSongs,
    setFavoriteSongs: setFavoriteSongs,
    hasFavoriteSongs: hasFavoriteSongs,
    getFavoriteSongsNewestFirst: getFavoriteSongsNewestFirst,
    isSongFavorited: isSongFavorited,
    findFavoriteIndexByKey: findFavoriteIndexByKey,
    createSavedFavoriteSong: createSavedFavoriteSong,
    toggleSong: toggleSong
  };
})();
