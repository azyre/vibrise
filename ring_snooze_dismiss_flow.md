# Vibrise Ring / Snooze / Dismiss Flow

> 版本：v1.0  
> 更新日期：2026-02-25  
> 状态：按当前 prototype 行为整理

---

## 一、目的

这份文档描述当前 `html prototype` 中响铃、贪睡、恢复、dismiss 的真实状态流。

目标是让后续 iOS / Android 实现对齐同一套行为，不靠“看页面猜逻辑”。

---

## 二、核心状态

当前流程可以抽象成 4 个主要状态：

1. `idle`
   首页常态，未响铃

2. `ringing`
   响铃页打开，音乐正在播放或准备播放

3. `snoozed`
   贪睡层打开，响铃页作为 underlay 保留，音乐暂停

4. `dismissed`
   当前响铃流程结束，返回首页

说明：

- 当前 prototype 没有单独的 dismissed 页面
- `dismissed` 是一个“流程结果”，不是长期停留页面

---

## 三、主流程概览

```text
idle
  -> alarm trigger / testRing
  -> ringing

ringing
  -> hold main button >= 550ms
  -> dismissed -> idle

ringing
  -> press main button but release before 550ms
  -> snoozed

snoozed
  -> countdown reaches 0
  -> ringing

snoozed
  -> tap "Cancel Snooze"
  -> ringing
```

---

## 四、进入 Ringing

### 入口 1：真实闹钟触发

来源：`js/alarm.js`

逻辑：

- `checkAlarms()` 每秒轮询
- 命中 `alarmDomain.shouldTriggerAlarmAtTime(...)` 后调用 `triggerRing()`
- 一次性闹钟（`days.length === 0`）会先被删除，再进入响铃

### 入口 2：测试触发

来源：`testRing()`

- `testRing()` 直接调用 `triggerRing()`
- 行为上与真实响铃基本一致

### 进入后做的事

来源：`js/alarm/ring-controller.js`

- 打开 `ringScreen`
- 使用 `fadeOnly` 模式从首页切到响铃页
- 先同步首页背景到响铃页
- 启动 `ringClockInterval`，每秒更新时间和日期
- 获取 location 和 weather
- 更新天气 UI
- 如果首页背景当前不可用，则对响铃页应用天气背景
- 根据天气和时间选歌
- 开始播放音乐

---

## 五、Ringing 状态下的交互

主按钮的交互不是“一个按钮两个明确点击区”，而是：

- 按下并持续超过 `550ms`：`dismiss`
- 按下后在 `550ms` 内松开：`snooze`

对应函数：

- `startRingHold()`
- `cancelRingHold()`
- `endRingHold()`

当前阈值：

- hold threshold = `550ms`

当前行为解释：

- `startRingHold()` 启动一个 `setTimeout`
- 超过 550ms 后直接执行 `dismiss()`
- 如果用户提前松手，`endRingHold()` 会走 `snooze()`

这意味着当前主按钮语义是：

- `hold to dismiss`
- `tap to snooze`

---

## 六、进入 Snoozed

来源：`js/ui/overlays.js -> snooze()`

进入动作：

1. 先执行 `audioService.fadeOut(350, ...)`
2. 给 `ringScreen` 加 `underlay-scaled`
3. 显示 `snoozeOverlay`
4. 初始化倒计时为 `300` 秒
5. 每秒刷新 `snoozeTimer`

当前关键参数：

- fade out duration = `350ms`
- snooze duration = `300s` = `5min`

重要语义：

- 当前不会重新选歌
- 当前不会关闭 `ringScreen`
- 当前只是暂停当前播放链路，并在 overlay 上显示倒计时

---

## 七、Snoozed 结束后的两种返回

### 路径 1：倒计时结束自动恢复

当 `remaining <= 0`：

- 清掉 `state.timers.snoozeCountdown`
- 隐藏 `snoozeOverlay`
- 移除 `ringScreen` 上的 `underlay-scaled`
- 执行 `audioService.resumeWithFade(500)`

### 路径 2：用户手动取消贪睡

来源：`cancelSnooze()`

- 清掉 `state.timers.snoozeCountdown`
- 隐藏 `snoozeOverlay`
- 移除 `ringScreen` 上的 `underlay-scaled`
- 执行 `audioService.resumeWithFade(500)`

当前关键参数：

- resume fade duration = `500ms`

重要语义：

- 恢复的是当前歌曲/当前播放链路
- 不是重新 fetch 天气
- 不是重新选歌
- 不是从头再进一次 `triggerRing()`

---

## 八、Dismiss

来源：`dismiss()`

当前行为：

1. 暂停 `audioPlayer`
2. 把 `audioPlayer.currentTime` 归零
3. 停止 fallback melody
4. 清理音量渐进 interval
5. 如果当前歌曲有封面图，用封面图更新首页背景
6. 清理 `ringClockInterval`
7. 隐藏 `snoozeOverlay`
8. 移除 `ringScreen` 的 `underlay-scaled`
9. 执行 `closeRingScreen()`
10. `renderHomeScreen()`

当前结果：

- 不会进入单独的 dismissed 页面
- 直接回首页
- 当前歌曲播放被视为彻底结束

---

## 九、音频行为

来源：`js/services/audio.js`

### 响铃开始

- `playSong(song)` 会把音量先设为 `0`
- 然后渐进增大音量
- 当前 ramp 速度约为 `30s` 增到满音量

### 贪睡

- `fadeOut(350)` 将当前播放快速淡出
- 如果是正常 `audioPlayer`，会 `pause()`，但不清空当前 `src`

### 贪睡恢复

- `resumeWithFade(500)` 优先恢复当前 `audioPlayer`
- 从 `volume = 0` 淡入到 `1`
- 只有在没有可恢复的 `audioPlayer` 时，才 fallback 到 `playSong(currentSong)`

### Dismiss

- `dismiss()` 会把播放头归零
- 因此 dismiss 后再下一次响铃，视为一轮新的播放流程

---

## 十、当前状态机的实现要点

为了未来原生端对齐，建议把下面这些视为“现行规则”：

- `ringing -> snoozed` 由“短按主按钮”触发
- `ringing -> dismissed` 由“长按主按钮 >= 550ms”触发
- `snoozed -> ringing` 有两条路：自动恢复、手动取消
- snooze 恢复不是重新拉取上下文，而是恢复当前播放
- dismiss 会彻底结束本轮响铃，并返回首页

---

## 十一、迁移到原生时需要保持一致的部分

以下行为建议 iOS / Android 都保持一致：

- 550ms 的 hold-to-dismiss 语义
- 5 分钟 snooze 默认值
- snooze 恢复继续当前播放，而不是重新挑歌
- dismiss 后直接回首页
- ring 和 snooze 的层级关系：ring 是 underlay，snooze 是 overlay

以下行为可以允许平台重实现，但语义不变：

- fade / scale 的具体动画参数
- 按钮触觉反馈
- 音频淡入淡出的底层实现
- 时间刷新 UI 的具体实现方式

---

## 十二、当前已知边界

当前 prototype 的流程语义已经清楚，但正式 App 时还需要补 3 个决策：

1. snooze 时如果 App 退到后台，倒计时和恢复策略怎么做
2. dismiss 后首页背景是否始终用当前封面图，还是回到天气背景
3. 如果音频播放失败，ringing 页的 fallback UI / fallback sound 是否需要更明确状态
