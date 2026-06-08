// ====== ALARM SETTING ======

function openAlarmSetting(alarmId) {
  if (alarmId) {
    var alarm = alarmRingStore.findAlarmById(alarmId);
    if (alarm) {
      alarmRingStore.setEditingAlarmId(alarm.id);
      alarmRingStore.setSelectedHour(alarm.hour);
      alarmRingStore.setSelectedMinute(alarm.minute);
      alarmRingStore.setSelectedDays(alarm.days.slice());
    }
  } else {
    alarmRingStore.clearEditingAlarmId();
    alarmRingStore.resetAlarmSelection();
  }

  buildTimePicker();
  buildDaySelector();
  showSettingOverlay();
}

function showSettingOverlay() {
  layerCoordinator.openOverlay('alarmSettingScreen', 'homeScreen');
}

function hideSettingOverlay() {
  layerCoordinator.closeOverlay('alarmSettingScreen', 'homeScreen');
}

function buildTimePicker() {
  var hourScroll = document.getElementById('hourScroll');
  var minuteScroll = document.getElementById('minuteScroll');

  hourScroll.innerHTML = '';
  var hTop = document.createElement('div');
  hTop.style.height = '130px';
  hourScroll.appendChild(hTop);
  for (var i = 0; i < 24; i++) {
    var el = document.createElement('div');
    el.className = 'time-picker-item';
    el.textContent = String(i).padStart(2, '0');
    el.dataset.value = i;
    (function(idx) {
      el.onclick = function() {
        hourScroll.scrollTo({ top: idx * 60, behavior: 'smooth' });
      };
    })(i);
    hourScroll.appendChild(el);
  }
  var hBot = document.createElement('div');
  hBot.style.height = '130px';
  hourScroll.appendChild(hBot);

  minuteScroll.innerHTML = '';
  var mTop = document.createElement('div');
  mTop.style.height = '130px';
  minuteScroll.appendChild(mTop);
  for (var j = 0; j < 60; j += 5) {
    var mel = document.createElement('div');
    mel.className = 'time-picker-item';
    mel.textContent = String(j).padStart(2, '0');
    mel.dataset.value = j;
    (function(idx) {
      mel.onclick = function() {
        minuteScroll.scrollTo({ top: idx * 60, behavior: 'smooth' });
      };
    })(j / 5);
    minuteScroll.appendChild(mel);
  }
  var mBot = document.createElement('div');
  mBot.style.height = '130px';
  minuteScroll.appendChild(mBot);

  var hRaf = null;
  hourScroll.onscroll = function() {
    if (hRaf) cancelAnimationFrame(hRaf);
    hRaf = requestAnimationFrame(function() {
      updatePickerTransforms(hourScroll);
      updateFromScroll(hourScroll, 'hour');
    });
  };

  var mRaf = null;
  minuteScroll.onscroll = function() {
    if (mRaf) cancelAnimationFrame(mRaf);
    mRaf = requestAnimationFrame(function() {
      updatePickerTransforms(minuteScroll);
      updateFromScroll(minuteScroll, 'minute');
    });
  };

  setTimeout(function() {
    hourScroll.scrollTop = alarmRingStore.getSelectedHour() * 60;
    minuteScroll.scrollTop = (alarmRingStore.getSelectedMinute() / 5) * 60;
    updatePickerTransforms(hourScroll);
    updatePickerTransforms(minuteScroll);
  }, 50);
}

function updateFromScroll(container, type) {
  var index = Math.round(container.scrollTop / 60);
  var items = container.querySelectorAll('.time-picker-item');
  if (index < 0 || index >= items.length) return;
  var val = parseInt(items[index].dataset.value, 10);
  if (type === 'hour') alarmRingStore.setSelectedHour(val);
  else alarmRingStore.setSelectedMinute(val);
}

function updatePickerTransforms(container) {
  var items = container.querySelectorAll('.time-picker-item');
  var scrollTop = container.scrollTop;
  var halfH = container.clientHeight / 2;

  items.forEach(function(el, i) {
    var itemCenter = i * 60 + 160;
    var offset = (itemCenter - scrollTop - halfH) / 60;
    var absOff = Math.abs(offset);
    var translateY = 0;

    var rotX = offset * -12;
    var s = Math.max(0.82, 1 - absOff * 0.08);
    var tz = -absOff * 4;

    if (absOff < 0.35) {
      el.style.color = 'rgba(255,255,255,1)';
      el.style.fontWeight = '500';
      el.style.textShadow = 'none';
      el.style.opacity = '1';
      el.style.fontSize = '48px';
      el.style.letterSpacing = '-0.04em';
      el.style.mixBlendMode = 'normal';
    } else if (absOff < 1.2) {
      translateY = offset > 0 ? 2 : -2;
      el.style.color = 'rgba(255,255,255,0.2)';
      el.style.fontWeight = '400';
      el.style.textShadow = 'none';
      el.style.opacity = '1';
      el.style.fontSize = '40px';
      el.style.letterSpacing = '-0.04em';
      el.style.mixBlendMode = 'plus-lighter';
    } else if (absOff < 2.2) {
      translateY = offset > 0 ? -18 : 18;
      el.style.color = 'rgba(255,255,255,0.1)';
      el.style.fontWeight = '400';
      el.style.textShadow = 'none';
      el.style.opacity = '1';
      el.style.fontSize = '36px';
      el.style.letterSpacing = '-0.04em';
      el.style.mixBlendMode = 'plus-lighter';
    } else {
      var alpha3 = Math.max(0.08, 0.18 - absOff * 0.05);
      el.style.color = 'rgba(255,255,255,' + alpha3 + ')';
      el.style.fontWeight = '300';
      el.style.textShadow = 'none';
      el.style.opacity = String(Math.max(0.08, 0.28 - absOff * 0.08));
      el.style.fontSize = '24px';
      el.style.letterSpacing = '0';
      el.style.mixBlendMode = 'normal';
    }

    el.style.transform =
      'perspective(800px) rotateX(' + rotX + 'deg) translateY(' + translateY + 'px) scale(' + s + ') translateZ(' + tz + 'px)';
  });
}

function buildDaySelector() {
  var container = document.getElementById('daySelector');
  container.innerHTML = '';
  alarmRingStore.getDisplayOrder().forEach(function(i) {
    var btn = document.createElement('button');
    btn.className = 'day-btn' + (alarmRingStore.getSelectedDays().includes(i) ? ' active' : '');
    btn.textContent = alarmRingStore.getDayLabelsShort()[i];
    btn.onclick = function() { toggleDay(i, btn); };
    container.appendChild(btn);
  });
}

function toggleDay(day, btn) {
  var selectedDays = alarmRingStore.getSelectedDays();
  var idx = selectedDays.indexOf(day);
  if (idx >= 0) selectedDays.splice(idx, 1);
  else selectedDays.push(day);
  btn.classList.toggle('active');
}

function cancelSetting() {
  alarmRingStore.clearEditingAlarmId();
  hideSettingOverlay();
  layerCoordinator.showScreen('homeScreen', {
    onShow: renderHomeScreen
  });
}
