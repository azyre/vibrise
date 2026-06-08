var musicSelectionDomain = (function() {
  var DEFAULT_WEATHER_TAG = 'lounge+downtempo';

  function timeToSpeed(hour) {
    if (hour < 5) return 'verylow';
    if (hour < 7) return 'low';
    if (hour < 11) return 'medium';
    if (hour < 18) return 'high';
    if (hour < 21) return 'medium';
    return 'low';
  }

  function weatherToTag(weather, getWeatherInfoFn) {
    if (!weather || typeof weather.weathercode !== 'number' || typeof getWeatherInfoFn !== 'function') {
      return DEFAULT_WEATHER_TAG;
    }

    var weatherInfo = getWeatherInfoFn(weather.weathercode);
    return weatherInfo && weatherInfo.tag ? weatherInfo.tag : DEFAULT_WEATHER_TAG;
  }

  function resolveSongProfile(weather, now, getWeatherInfoFn) {
    now = now || new Date();

    return {
      strategyId: 'weather-time',
      tag: weatherToTag(weather, getWeatherInfoFn),
      speed: timeToSpeed(now.getHours())
    };
  }

  return {
    resolveSongProfile: resolveSongProfile,
    timeToSpeed: timeToSpeed,
    weatherToTag: weatherToTag
  };
})();
