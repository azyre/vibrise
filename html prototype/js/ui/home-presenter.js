var homePresenter = (function() {
  function getAlarmList() {
    return document.getElementById('alarmList');
  }

  function getNoAlarmState() {
    return document.getElementById('noAlarmState');
  }

  function renderText(selector, text) {
    document.querySelectorAll(selector).forEach(function(el) {
      el.textContent = text;
    });
  }

  function setEmptyStateVisible(visible) {
    var noAlarm = getNoAlarmState();
    if (!noAlarm) return;
    noAlarm.style.display = visible ? '' : 'none';
  }

  function clearAlarmList() {
    var list = getAlarmList();
    if (!list) return;
    list.innerHTML = '';
  }

  function createAlarmCard(alarm, handlers) {
    var card = document.createElement('div');
    card.className = 'alarm-card';
    card.onclick = function() {
      handlers.onOpenAlarm(alarm.id);
    };

    if (!alarm.enabled) card.classList.add('disabled');

    var top = document.createElement('div');
    top.className = 'alarm-card-top';

    var testBtn = document.createElement('button');
    testBtn.className = 'alarm-card-test-btn';
    testBtn.textContent = 'Test';
    testBtn.onclick = function(e) {
      e.stopPropagation();
      handlers.onPreviewAlarm(alarm.source);
    };
    top.appendChild(testBtn);

    var toggle = document.createElement('button');
    toggle.className = 'toggle' + (alarm.enabled ? ' on' : '');
    toggle.innerHTML = '<div class="toggle-knob"></div>';
    toggle.onclick = function(e) {
      e.stopPropagation();
      handlers.onToggleAlarm(alarm.id);
    };
    top.appendChild(toggle);

    card.appendChild(top);

    var time = document.createElement('div');
    time.className = 'alarm-card-time';
    time.textContent = alarm.timeText;
    card.appendChild(time);

    var days = document.createElement('div');
    days.className = 'alarm-card-days';
    alarm.dayLabels.forEach(function(dayLabel) {
      var day = document.createElement('div');
      day.className = 'alarm-card-day-label' + (dayLabel.active ? ' active' : '');
      day.textContent = dayLabel.label;
      days.appendChild(day);
    });
    card.appendChild(days);

    return card;
  }

  function renderAlarmList(alarms, handlers) {
    var list = getAlarmList();
    if (!list) return;

    list.innerHTML = '';

    var fragment = document.createDocumentFragment();
    alarms.forEach(function(alarm) {
      fragment.appendChild(createAlarmCard(alarm, handlers));
    });
    list.appendChild(fragment);
  }

  function renderScreen(model, handlers) {
    if (!model.hasAlarms) {
      setEmptyStateVisible(true);
      clearAlarmList();
      return;
    }

    setEmptyStateVisible(false);
    renderAlarmList(model.alarms, handlers);
  }

  function updateClock(timeText) {
    renderText('.home-clock-el', timeText);
  }

  function updateDate(dateText) {
    renderText('.home-date-el', dateText);
  }

  return {
    setEmptyStateVisible: setEmptyStateVisible,
    clearAlarmList: clearAlarmList,
    renderAlarmList: renderAlarmList,
    renderScreen: renderScreen,
    updateClock: updateClock,
    updateDate: updateDate
  };
})();
