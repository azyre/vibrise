var alarmDomain = {
  arraysEqual: function(a, b) {
    return a.length === b.length && a.every(function(value, index) {
      return value === b[index];
    });
  },

  getDaysLabel: function(days) {
    var sorted = days.slice().sort();
    if (sorted.length === 0) return 'Once';
    if (sorted.length === 7) return 'Every day';
    if (this.arraysEqual(sorted, [1, 2, 3, 4, 5])) return 'Weekdays';
    if (this.arraysEqual(sorted, [0, 6])) return 'Weekends';
    return sorted.map(function(day) {
      return state.constants.DAY_LABELS[day];
    }).join(', ');
  },

  shouldTriggerAlarmAtTime: function(alarm, hour, minute, dayIndex) {
    if (!alarm || !alarm.enabled) return false;
    if (hour !== alarm.hour || minute !== alarm.minute) return false;
    return alarm.days.length === 0 || alarm.days.includes(dayIndex);
  }
};
