audioService.init(document.getElementById('audioPlayer'));
storageService.loadAlarms();
if (enforceSingleAlarmLimit()) storageService.saveAlarms();
storageService.loadFavoriteSongs();
ringSession.bindUI();
initThanksOverlay();
prepareShareCard();
startHomeClock();
renderHomeScreen();
