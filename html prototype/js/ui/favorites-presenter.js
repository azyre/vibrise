var favoritesPresenter = (function() {
  function getList() {
    return document.getElementById('favoritesList');
  }

  function getEmptyState() {
    return document.getElementById('favoritesEmpty');
  }

  function setEmptyStateVisible(visible) {
    var empty = getEmptyState();
    if (!empty) return;
    empty.style.display = visible ? 'flex' : 'none';
  }

  function setListVisible(visible) {
    var list = getList();
    if (!list) return;
    list.style.display = visible ? 'flex' : 'none';
  }

  function clearList() {
    var list = getList();
    if (!list) return;
    list.innerHTML = '';
  }

  function createFavoriteSongCard(song) {
    var card = document.createElement('div');
    card.className = 'favorite-song-card';

    var cover = document.createElement('img');
    cover.className = 'favorite-song-cover';
    cover.src = song.image;
    cover.alt = song.title;
    card.appendChild(cover);

    var copy = document.createElement('div');
    copy.className = 'favorite-song-copy';

    var title = document.createElement('div');
    title.className = 'favorite-song-title';
    title.textContent = song.title;
    copy.appendChild(title);

    var artist = document.createElement('div');
    artist.className = 'favorite-song-artist';
    artist.textContent = song.artist;
    copy.appendChild(artist);

    card.appendChild(copy);
    return card;
  }

  function renderSongList(songs) {
    var list = getList();
    if (!list) return;

    list.innerHTML = '';

    var fragment = document.createDocumentFragment();
    songs.forEach(function(song) {
      fragment.appendChild(createFavoriteSongCard(song));
    });
    list.appendChild(fragment);
  }

  function renderScreen(model) {
    if (!model.hasSongs) {
      setEmptyStateVisible(true);
      setListVisible(false);
      clearList();
      return;
    }

    setEmptyStateVisible(false);
    setListVisible(true);
    renderSongList(model.songs);
  }

  return {
    setEmptyStateVisible: setEmptyStateVisible,
    setListVisible: setListVisible,
    clearList: clearList,
    renderSongList: renderSongList,
    renderScreen: renderScreen
  };
})();
