var thanksOverlayController = (function() {
  var THANKS_VISIBLE_MS = 1600;
  var COFFEE_RETURN_MIN_MS = 700;
  var COFFEE_URL = 'https://buymeacoffee.com';
  var THANKS_MESSAGES = [
    'Thank You',
    'Much Appreciated',
    "You're Awesome",
    'Truly Grateful',
    'Made My Day',
    'Deeply Touched',
    'Greatly Honored'
  ];

  var pendingCoffeeReturn = false;
  var pendingStartedAt = 0;
  var hideTimer = null;
  var lastMessage = '';

  function getOverlay() {
    return document.getElementById('thanksOverlay');
  }

  function getCurrentUnderlayId() {
    if (typeof layerCoordinator !== 'undefined' && layerCoordinator.isLayerVisible('ringScreen')) {
      return 'ringScreen';
    }

    return 'homeScreen';
  }

  function clearHideTimer() {
    if (!hideTimer) return;
    clearTimeout(hideTimer);
    hideTimer = null;
  }

  function getMessageElement() {
    return document.querySelector('#thanksOverlay .thanks-message');
  }

  function getRandomMessage() {
    if (THANKS_MESSAGES.length <= 1) return THANKS_MESSAGES[0] || '';

    var nextMessage = lastMessage;

    while (nextMessage === lastMessage) {
      nextMessage = THANKS_MESSAGES[Math.floor(Math.random() * THANKS_MESSAGES.length)];
    }

    lastMessage = nextMessage;
    return nextMessage;
  }

  function splitMessageIntoLines(message) {
    var words = message.split(' ');
    if (words.length <= 1) return [message];
    if (words.length === 2) return words;

    var bestIndex = 1;
    var smallestDiff = Infinity;

    for (var i = 1; i < words.length; i += 1) {
      var firstLine = words.slice(0, i).join(' ');
      var secondLine = words.slice(i).join(' ');
      var diff = Math.abs(firstLine.length - secondLine.length);

      if (diff < smallestDiff) {
        smallestDiff = diff;
        bestIndex = i;
      }
    }

    return [
      words.slice(0, bestIndex).join(' '),
      words.slice(bestIndex).join(' ')
    ];
  }

  function setRandomMessage() {
    var messageElement = getMessageElement();
    if (!messageElement) return;

    var lines = splitMessageIntoLines(getRandomMessage());
    messageElement.innerHTML = lines.map(function(line) {
      return '<span>' + line + '</span>';
    }).join('');
  }

  function open() {
    var overlay = getOverlay();
    if (!overlay || typeof layerCoordinator === 'undefined') return;

    clearHideTimer();
    setRandomMessage();

    var underlayId = getCurrentUnderlayId();
    overlay.dataset.underlayId = underlayId;
    layerCoordinator.openOverlay('thanksOverlay', underlayId);

    hideTimer = setTimeout(function() {
      close();
    }, THANKS_VISIBLE_MS);
  }

  function close() {
    var overlay = getOverlay();
    if (!overlay || typeof layerCoordinator === 'undefined') return;

    clearHideTimer();
    layerCoordinator.closeOverlay('thanksOverlay', overlay.dataset.underlayId || getCurrentUnderlayId());
  }

  function markPendingReturn() {
    pendingCoffeeReturn = true;
    pendingStartedAt = Date.now();
  }

  function maybeShowThanks() {
    if (!pendingCoffeeReturn) return;
    if (document.hidden) return;
    if (Date.now() - pendingStartedAt < COFFEE_RETURN_MIN_MS) return;

    pendingCoffeeReturn = false;
    open();
  }

  function openCoffeeLink() {
    var popup = window.open(COFFEE_URL, '_blank');
    if (!popup) return;

    markPendingReturn();
  }

  function init() {
    window.addEventListener('focus', maybeShowThanks);
    document.addEventListener('visibilitychange', function() {
      if (!document.hidden) maybeShowThanks();
    });
  }

  return {
    init: init,
    openCoffeeLink: openCoffeeLink,
    open: open,
    close: close
  };
})();

function initThanksOverlay() {
  thanksOverlayController.init();
}

function handleCoffeeClick() {
  thanksOverlayController.openCoffeeLink();
}

function openThanksOverlay() {
  thanksOverlayController.open();
}

function closeThanksOverlay() {
  thanksOverlayController.close();
}
