function getShareFileName() {
  return shareState.getFileName();
}

function prepareShareCard() {
  return shareRenderer.prepareCard();
}

function openShareOverlay() {
  prepareShareCard();
  layerCoordinator.openOverlay('shareOverlay', 'ringScreen', {
    setDisplay: false,
    hideAfterTransition: false
  });
}

function closeShareOverlay() {
  layerCoordinator.closeOverlay('shareOverlay', 'ringScreen', {
    hideAfterTransition: false
  });
}

function canvasToBlob(canvas) {
  return new Promise(function(resolve, reject) {
    canvas.toBlob(function(blob) {
      if (!blob) {
        reject(new Error('Failed to export share image'));
        return;
      }
      resolve(blob);
    }, 'image/png');
  });
}

async function downloadShareCanvas(canvas) {
  var blob = await canvasToBlob(canvas);
  var url = URL.createObjectURL(blob);
  var link = document.createElement('a');

  link.href = url;
  link.download = getShareFileName();
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  setTimeout(function() {
    URL.revokeObjectURL(url);
  }, 1000);

  return blob;
}

async function saveShareImage() {
  try {
    var canvas = await shareRenderer.renderCardCanvas();
    await downloadShareCanvas(canvas);
  } catch (error) {
    console.error('Failed to save share image:', error);
  }
}

async function shareCurrentSong() {
  try {
    var canvas = await shareRenderer.renderCardCanvas();
    var blob = await canvasToBlob(canvas);
    var file = new File([blob], getShareFileName(), { type: 'image/png' });

    if (navigator.share && (!navigator.canShare || navigator.canShare({ files: [file] }))) {
      await navigator.share({
        title: 'Share from Vibrise',
        text: 'Shared from Vibrise',
        files: [file]
      });
      return;
    }

    await downloadShareCanvas(canvas);
  } catch (error) {
    if (error && error.name === 'AbortError') return;
    console.error('Failed to share current song:', error);
  }
}
