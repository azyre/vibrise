# Vibrise Service Interfaces

> 版本：v1.0  
> 更新日期：2026-02-25  
> 状态：按当前 prototype 实现整理

---

## 一、目的

这份文档描述当前 `html prototype` 中各个 service 的接口、依赖、返回值、fallback 和迁移注意点。

目标：

- 让后续 iOS / Android 直接按接口语义实现
- 区分哪些 service 已经接近正式结构，哪些还混有 prototype UI 细节

---

## 二、总览

当前主要 service：

- `storageService`
- `audioService`
- `weatherService`
- `musicSourceService`

它们共同依赖：

- `state`
- 部分 `domain`
- 浏览器能力，如 `localStorage`、`fetch`、`HTMLAudioElement`、`AudioContext`、`geolocation`

---

## 三、storageService

来源：`html prototype/js/services/storage.js`

### 职责

- 持久化闹钟数据
- 持久化收藏歌曲
- 在启动时把本地存储恢复到 `state`

### 接口

#### `storageService.saveAlarms()`

输入：

- 无显式参数
- 隐式读取 `state.alarm.alarms`
- 隐式读取 `state.alarm.nextAlarmId`

副作用：

- 写入 `localStorage['vibrise_alarms']`
- 写入 `localStorage['vibrise_nextId']`

返回：

- 无返回值

fallback：

- `try/catch` 吞错
- 存储失败时不会抛异常

#### `storageService.loadAlarms()`

输入：

- 无显式参数

副作用：

- 读取 `localStorage`
- 写回 `state.alarm.alarms`
- 写回 `state.alarm.nextAlarmId`

返回：

- 无返回值

#### `storageService.saveFavoriteSongs()`

输入：

- 无显式参数
- 隐式读取 `state.favorites.favoriteSongs`

副作用：

- 写入 `localStorage['vibrise_favorite_songs']`

返回：

- 无返回值

#### `storageService.loadFavoriteSongs()`

输入：

- 无显式参数

副作用：

- 从 `localStorage` 恢复 `state.favorites.favoriteSongs`

清洗规则：

- 非数组时重置为空数组

返回：

- 无返回值

### 迁移建议

- iOS / Android 中应改为显式 repository / persistence service
- 不建议继续依赖全局 `state`
- 当前 prototype 已把“只保留一个 alarm”的限制移到业务动作层，而不是持久化层

---

## 四、audioService

来源：`html prototype/js/services/audio.js`

### 职责

- 初始化主 `audioPlayer`
- 播放歌曲
- 音量渐入
- 淡出 / 恢复
- 在没有可播 URL 时使用 fallback melody

### 接口

#### `audioService.init(audioEl)`

输入：

- `audioEl: HTMLAudioElement`

副作用：

- 写入 `state.playback.audioPlayer`

返回：

- 无返回值

#### `audioService.playSong(song)`

输入：

- `song`
- 主要读取 `song.audio` 或 `song.audiodownload`

行为：

- 清理已有音量 ramp
- 停止 fallback melody
- 如果有音频 URL，则设置 `audioPlayer.src`
- 从音量 `0` 开始播放并渐入
- 如果没有音频 URL，则播放 fallback melody

返回：

- 无显式返回值

fallback：

- 无 URL 时使用内置 melody
- 浏览器自动播放失败时，等待下一次用户点击再重试播放

#### `audioService.fadeOut(durationMs, onDone)`

输入：

- `durationMs: number`
- `onDone?: function`

行为：

- 如果当前是 `audioPlayer` 在播，则按 16ms step 淡出后 `pause()`
- 如果当前是 fallback melody，则淡出后停止 fallback
- 如果没有正在播的内容，直接调用 `onDone`

返回：

- 无显式返回值

#### `audioService.resumeWithFade(durationMs)`

输入：

- `durationMs: number`

行为：

- 如果 `currentSong + audioPlayer.src` 存在，则恢复当前播放并从 0 淡入
- 否则如果 `currentSong` 存在，则退回到 `playSong(currentSong)`

返回：

- 无显式返回值

#### `audioService.stopFallbackMelody()`

输入：

- 无

行为：

- 停止 fallback melody 所有 timer / audio context

#### `audioService.playFallbackMelody()`

输入：

- 无

行为：

- 用 Web Audio API 生成简易旋律
- 支持渐入
- 浏览器音频上下文被挂起时，会等待用户点击 / touch 解锁

### 依赖 state

- `state.playback.audioPlayer`
- `state.playback.currentSong`
- `state.playback.volumeInterval`

### 迁移建议

- 原生端应拆成：
  - `AudioPlaybackService`
  - `VolumeEnvelope / FadeController`
  - 可选 `FallbackToneService`
- `playSong()` 和 fallback 逻辑已经接近 service 边界，可以保留语义
- 自动播放失败重试属于浏览器特例，原生端不需要照搬实现

---

## 五、weatherService

来源：`html prototype/js/services/weather.js`

### 职责

- 读取 location
- 拉取天气
- 管理天气缓存
- 提供天气码映射
- 生成天气背景 style 数据

### 接口

#### `weatherService.getWeatherInfo(code)`

输入：

- `code: number`

输出：

- 返回 weather info object：
  - `name`
  - `emoji`
  - `tag`
  - `orbColor1`
  - `orbColor2`
  - `bgEnd`

fallback：

- 未知天气码时按区间归类
- 最终默认回到 `weatherMap[2]`

#### `weatherService.fetchWeather(lat, lon)`

输入：

- `lat: number`
- `lon: number`

输出：

- 成功时返回 `current_weather` object
- 失败时返回缓存天气或 `null`

缓存规则：

- 使用 `state.cache.cachedWeather`
- TTL = `10 分钟`

#### `weatherService.getLocation()`

输入：

- 无

输出：

- `{ lat, lon }`

fallback：

- geolocation 不可用或失败时，返回默认坐标 `{ lat: 39.9, lon: 116.4 }`
- 成功或 fallback 后都会写入 `state.cache.cachedLocation`

#### `weatherService.generateWeatherStyle(code, temp)`

输入：

- `code: number`
- `temp: number`

输出：

- `{ bg, colors }`

用途：

- 供 UI 层生成首页/响铃页背景

#### `weatherService.spiceUpStyle(style)`

输入：

- `style: { bg, colors }`

行为：

- 原地修改 `style`
- 增加随机 accent 层与颜色池

#### `weatherService.getDaylightFactor()`

输入：

- 无

输出：

- `0..1` 之间的 daylight factor

用途：

- 控制 brightness / saturate / orb opacity

### 依赖 state

- `state.cache.cachedLocation`
- `state.cache.cachedWeather`
- `state.cache.cachedWeatherAt`

### 迁移建议

- 正式 App 中建议拆成：
  - `LocationService`
  - `WeatherApiService`
  - `WeatherPresentationMapper`
  - `WeatherBackgroundStyleBuilder`
- 当前 prototype 已不再把天气文本 UI 更新留在 service 中

---

## 六、musicSourceService

来源：`html prototype/js/services/music-source.js`

### 职责

- 调 Jamendo API
- 计算随机 offset
- 拉取候选歌曲
- 返回候选歌曲给上层编排流程

### 接口

#### `musicSourceService.searchJamendo(params)`

输入：

- `params: object`

默认参数：

- `client_id`
- `format=json`
- `limit=1`
- `vocalinstrumental=instrumental`
- `durationbetween=60_600`
- `audioformat=mp32`
- `imagesize=400`
- `include=musicinfo`

输出：

- 成功时返回单个 `song object`
- 失败时返回 `null`

#### `musicSourceService.getFullCount(params)`

输入：

- `params: object`

输出：

- 返回 Jamendo `results_fullcount`
- 失败时返回 `0`

#### `musicSourceService.fetchRandomSong(tag, speed)`

输入：

- `tag?: string`
- `speed?: string`

行为：

- 先用 `tag + speed` 调 `getFullCount()`
- 如果候选池 `>= 100`：
  - 在 `0..min(total, 500)` 范围随机 offset
  - 调 `searchJamendo()`
- 如果候选池 `< 100` 或没取到歌：
  - 去掉 `speed`，只保留 `tag` 再查一次
- 如果 tag-only 候选池 `>= 100`：
  - 再次随机 offset 取歌
- 如果仍然没有合适结果：
  - 退回到纯随机 offset 搜索

输出：

- `song | null`

#### `musicSourceService.pickSong(weather)`

输入：

- `weather`

行为：

1. 调 `musicSelectionDomain.resolveSongProfile(...)`
2. 计算 `tag` 和 `speed`
3. 非 demo 模式下尝试从 Jamendo 抓歌
4. 抓不到时从 `demoSongs` 兜底

输出：

- `song`

注意：

- 当前这个接口已经回到纯选歌语义
- 选歌规则已改为 v2 双维模型：天气决定 `tag`，时间决定 `speed`
- 响铃页 loading、封面展示、收藏按钮刷新、播放控制 已移到上层编排

### 依赖 state

- `state.config.JAMENDO_CLIENT_ID`
- `state.config.IS_DEMO`

### 额外依赖

- `musicSelectionDomain`
- `weatherService.getWeatherInfo`

### 迁移建议

- 正式 App 中建议拆成：
  - `JamendoApiService`
  - `MusicSelectionUseCase`
  - `RingPlaybackCoordinator`
  - `RingNowPlayingPresenter`
- `searchJamendo()` / `getFullCount()` / `fetchRandomSong()` / `pickSong()` 可以直接保留为 service / use case 语义
- 当前 prototype 中响铃页编排已经移到上层

---

## 七、当前接口的“可直接迁移度”

### 可直接迁移语义较高

- `storageService.saveAlarms()`
- `storageService.loadAlarms()`
- `storageService.saveFavoriteSongs()`
- `storageService.loadFavoriteSongs()`
- `audioService.playSong()`
- `audioService.fadeOut()`
- `audioService.resumeWithFade()`
- `weatherService.getWeatherInfo()`
- `weatherService.fetchWeather()`
- `weatherService.getLocation()`
- `weatherService.generateWeatherStyle()`
- `musicSourceService.searchJamendo()`
- `musicSourceService.getFullCount()`
- `musicSourceService.fetchRandomSong()`

### 迁移前建议重拆

- `audioService` 内部的 fallback melody 是否保留为产品能力
- `musicSourceService` 与 ring coordinator 的边界是否还要继续细化

原因：

- 这两块更像产品策略 / 编排边界，不一定应直接落在基础 service 层

---

## 八、推荐的原生层映射

| Prototype service | iOS / Android 推荐对应 |
|------|------|
| `storageService` | repository / persistence layer |
| `audioService` | audio playback service |
| `weatherService` | location + weather + style mapper |
| `musicSourceService` | Jamendo service + ring coordinator |

---

## 九、结论

当前 prototype 的 service 层已经有明显边界，但还不是完全纯净。

最值得保留的成果是：

- 接口名字和职责已经开始稳定
- fallback 语义已经明确
- 外部依赖边界已经出现

最值得在正式 App 启动前再继续收口的，是这两个点：

1. 评估 `audioService` 的 fallback melody 在正式版是否继续保留
2. 继续收紧响铃编排层和纯 service 层的边界
