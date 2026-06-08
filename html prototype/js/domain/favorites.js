var favoritesDomain = {
  getSongFavoriteKey: function(song) {
    if (!song) return '';
    return [
      song.id || '',
      song.name || '',
      song.artist_name || song.artist || '',
      song.image || ''
    ].join('::');
  },

  isSongFavorited: function(song, favoriteSongs) {
    var key = this.getSongFavoriteKey(song);
    if (!key) return false;
    return favoriteSongs.some(function(savedSong) {
      return savedSong.key === key;
    });
  }
};
