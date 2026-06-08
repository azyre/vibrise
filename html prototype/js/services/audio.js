var audioService = (function() {
  var fallbackAudioCtx = null;
  var fallbackTimeout = null;
  var fallbackMasterGain = null;
  var fallbackRampInterval = null;

  function clearVolumeRamp() {
    if (state.playback.volumeInterval) {
      clearInterval(state.playback.volumeInterval);
      state.playback.volumeInterval = null;
    }
  }

  function startVolumeRamp() {
    var audioPlayer = state.playback.audioPlayer;
    if (!audioPlayer) return;

    clearVolumeRamp();
    var vol = audioPlayer.volume || 0;
    state.playback.volumeInterval = setInterval(function() {
      vol = Math.min(1, vol + 1 / 30);
      audioPlayer.volume = vol;
      if (vol >= 1) clearVolumeRamp();
    }, 1000);
  }

  function stopFallbackMelody() {
    if (fallbackRampInterval) {
      clearInterval(fallbackRampInterval);
      fallbackRampInterval = null;
    }
    if (fallbackTimeout) {
      clearTimeout(fallbackTimeout);
      fallbackTimeout = null;
    }
    if (fallbackAudioCtx) {
      fallbackAudioCtx.close().catch(function() {});
      fallbackAudioCtx = null;
    }
    fallbackMasterGain = null;
  }

  function playFallbackMelody() {
    stopFallbackMelody();
    try {
      var ctx = new (window.AudioContext || window.webkitAudioContext)();
      fallbackAudioCtx = ctx;

      var master = ctx.createGain();
      master.gain.value = 0;
      master.connect(ctx.destination);
      fallbackMasterGain = master;

      var scales = [
        [523.25, 659.25, 783.99, 1046.50, 783.99, 659.25],
        [440.00, 554.37, 659.25, 880.00, 659.25, 554.37],
        [392.00, 493.88, 587.33, 783.99, 587.33, 493.88],
        [349.23, 440.00, 523.25, 698.46, 523.25, 440.00],
        [587.33, 739.99, 880.00, 1174.66, 880.00, 739.99]
      ];
      var notes = scales[Math.floor(Math.random() * scales.length)];
      var noteDuration = 0.35;
      var gap = 0.1;
      var cycleLen = notes.length * (noteDuration + gap) + 0.6;

      function playOneCycle(startTime) {
        notes.forEach(function(freq, i) {
          var t = startTime + i * (noteDuration + gap);
          var osc = ctx.createOscillator();
          var noteGain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.value = freq;
          noteGain.gain.setValueAtTime(0, t);
          noteGain.gain.linearRampToValueAtTime(0.35, t + 0.05);
          noteGain.gain.linearRampToValueAtTime(0, t + noteDuration);
          osc.connect(noteGain);
          noteGain.connect(master);
          osc.start(t);
          osc.stop(t + noteDuration);
        });
      }

      function startLoop() {
        var vol = 0;
        if (fallbackRampInterval) clearInterval(fallbackRampInterval);
        fallbackRampInterval = setInterval(function() {
          vol = Math.min(1, vol + 1 / 30);
          if (fallbackMasterGain) fallbackMasterGain.gain.value = vol;
          if (vol >= 1) clearInterval(fallbackRampInterval);
        }, 1000);

        function loop() {
          playOneCycle(ctx.currentTime + 0.05);
          fallbackTimeout = setTimeout(loop, cycleLen * 1000);
        }
        loop();
      }

      if (ctx.state === 'suspended') {
        ctx.resume().then(startLoop).catch(function() {});
        var unlockAudio = function() {
          if (fallbackAudioCtx && fallbackAudioCtx.state === 'suspended') {
            fallbackAudioCtx.resume().then(startLoop).catch(function() {});
          }
          document.removeEventListener('click', unlockAudio);
          document.removeEventListener('touchstart', unlockAudio);
        };
        document.addEventListener('click', unlockAudio);
        document.addEventListener('touchstart', unlockAudio);
      } else {
        startLoop();
      }
    } catch (e) {}
  }

  function playSong(song) {
    var audioPlayer = state.playback.audioPlayer;
    if (!audioPlayer) return;

    clearVolumeRamp();
    stopFallbackMelody();

    var url = song.audio || song.audiodownload || '';
    if (!url) {
      playFallbackMelody();
      return;
    }

    audioPlayer.src = url;
    audioPlayer.volume = 0;
    var p = audioPlayer.play();
    if (p) {
      p.then(function() {
        startVolumeRamp();
      }).catch(function() {
        var resume = function() {
          audioPlayer.play().then(function() {
            document.removeEventListener('click', resume);
            startVolumeRamp();
          }).catch(function() {});
        };
        document.addEventListener('click', resume);
      });
    } else {
      startVolumeRamp();
    }
  }

  function fadeOut(durationMs, onDone) {
    var audioPlayer = state.playback.audioPlayer;
    clearVolumeRamp();

    if (audioPlayer && audioPlayer.src && !audioPlayer.paused) {
      var startVol = audioPlayer.volume;
      var steps = Math.max(1, Math.round(durationMs / 16));
      var step = 0;
      var fadeTimer = setInterval(function() {
        step++;
        var progress = step / steps;
        audioPlayer.volume = Math.max(0, startVol * (1 - progress));
        if (step >= steps) {
          clearInterval(fadeTimer);
          audioPlayer.pause();
          if (onDone) onDone();
        }
      }, 16);
      return;
    }

    if (fallbackMasterGain && fallbackAudioCtx) {
      var fallbackStartVol = fallbackMasterGain.gain.value;
      var fallbackSteps = Math.max(1, Math.round(durationMs / 16));
      var fallbackStep = 0;
      var fallbackFadeTimer = setInterval(function() {
        fallbackStep++;
        var fallbackProgress = fallbackStep / fallbackSteps;
        fallbackMasterGain.gain.value = Math.max(0, fallbackStartVol * (1 - fallbackProgress));
        if (fallbackStep >= fallbackSteps) {
          clearInterval(fallbackFadeTimer);
          stopFallbackMelody();
          if (onDone) onDone();
        }
      }, 16);
      return;
    }

    if (onDone) onDone();
  }

  function resumeWithFade(durationMs) {
    var audioPlayer = state.playback.audioPlayer;
    var currentSong = state.playback.currentSong;
    clearVolumeRamp();

    if (currentSong && audioPlayer && audioPlayer.src) {
      audioPlayer.volume = 0;
      var p = audioPlayer.play();
      if (p) p.catch(function() {});

      var steps = Math.max(1, Math.round(durationMs / 16));
      var step = 0;
      state.playback.volumeInterval = setInterval(function() {
        step++;
        audioPlayer.volume = Math.min(1, step / steps);
        if (step >= steps) clearVolumeRamp();
      }, 16);
      return;
    }

    if (currentSong) playSong(currentSong);
  }

  function stopPlayback() {
    var audioPlayer = state.playback.audioPlayer;
    clearVolumeRamp();

    if (audioPlayer) {
      audioPlayer.pause();
      audioPlayer.currentTime = 0;
    }

    stopFallbackMelody();
  }

  function init(audioEl) {
    state.playback.audioPlayer = audioEl;
  }

  return {
    init: init,
    playSong: playSong,
    fadeOut: fadeOut,
    resumeWithFade: resumeWithFade,
    stopPlayback: stopPlayback,
    stopFallbackMelody: stopFallbackMelody,
    playFallbackMelody: playFallbackMelody
  };
})();
