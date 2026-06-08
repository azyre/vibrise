# Vibrise Prototype -> App Roadmap

> 版本：v1.0  
> 更新日期：2026-02-25  
> 状态：执行路线图

---

## 一、目标

这份文档定义 Vibrise 从当前 `html prototype` 走向正式 App 的推荐路径。

核心目标不是“尽快把 HTML 搬进 Xcode / Android Studio”，而是分阶段完成三件事：

1. 先把 **产品逻辑验证清楚**
2. 再把 **可迁移的业务层抽干净**
3. 最后分别落到 **iOS / Android 原生工程**

---

## 二、当前状态

当前原型已经不再是单文件结构，而是初步完成了分层：

- `js/store/state.js`：共享状态
- `js/domain/*.js`：纯规则层
- `js/services/*.js`：天气、存储、音频、音乐来源
- `js/alarm.js` + `js/alarm/*.js`：闹钟 runtime 与子流程
- `js/ui/*.js`：页面渲染、导航、背景、overlay
- `js/ui.js`：bootstrap

这意味着：

- UI 还属于原型层，未来不会直接复用
- `domain` 里的规则和一部分 `services` 接口定义，已经适合迁移到正式 App
- 现在最应该继续沉淀的是“规则、状态模型、服务边界”，而不是继续堆 UI 特例

---

## 三、什么时候继续留在 Prototype

以下事情还没稳定前，继续在 HTML prototype 迭代是对的：

- 首页、闹钟设置页、响铃页、贪睡页、收藏页的交互还在频繁改
- 视觉语言还在调，例如 glass 细节、过渡节奏、按钮反馈
- 响铃流程还在验证，例如淡入淡出、贪睡恢复、背景逻辑
- 音乐策略还在观察，例如 Jamendo 结果质量、fallback 频率、重复率

只要这些内容还在高频变化，就不要急着开始正式原生 UI 开发。

建议把 HTML prototype 再作为“交互实验场”使用 1 个阶段，只做两类事情：

- 验证用户可感知体验
- 提炼可迁移规则

---

## 四、什么时候切到正式 App

满足下面 4 个条件后，就可以开始正式 App 工程：

1. 核心页面结构稳定  
   不再频繁新增/删除大页面，只做局部细节调整

2. 核心流程稳定  
   从首页 -> 设闹钟 -> 响铃 -> 贪睡 / dismiss 的主流程不再反复改逻辑

3. 选歌规则稳定  
   `weather -> fuzzytags`、`time -> speed`、fallback 策略基本定稿

4. 数据模型稳定  
   alarm、favorites、playback、cache 的核心字段不再频繁变

如果这 4 条都满足，就不要继续把主要精力投在 prototype 架构优化上，应该开始正式 App。

---

## 五、推荐迁移顺序

### Phase 0：继续收口 Prototype

目标：把 HTML prototype 变成“规则清楚、边界清楚、便于翻译”的参考实现。

这一阶段继续做：

- 保持 `domain / services / ui` 边界
- 把新逻辑优先沉到 `domain`
- 给核心流程补文档，而不是继续堆历史遗留代码
- 避免重新出现 monolith 文件

这一阶段不要做：

- 引入构建工具
- 把 prototype 强行工程化成半正式前端项目
- 为了“像正式项目”而过度重写 UI

交付物：

- 稳定的 `html prototype`
- 清晰的规则文档
- 明确的数据模型和服务接口

### Phase 1：抽取 App Spec

目标：把 prototype 中真正要迁移的内容，变成独立于 UI 的规范。

建议沉淀 4 份规格：

- `alarm data model`
- `music selection rules`
- `weather visual mapping`
- `ring / snooze / dismiss state flow`

这一步的重点不是写代码，而是让未来 iOS / Android 都能按同一份规格实现。

交付物：

- 产品流程文档
- 状态机或流程图
- API 依赖与 fallback 说明

### Phase 2：先做 iOS 正式工程

推荐先做 iOS，再做 Android。

原因：

- 你现在的视觉方向明显更接近 iOS 语言
- iOS 端闹钟、音频、动画、系统整合的体验目标更明确
- 先做一端，更容易把业务层和服务层边界打磨出来

建议 iOS 工程拆分为：

- `Domain`
  放 alarm rule、music selection rule、favorites rule、date/time helper
- `Services`
  放 weather API、Jamendo API、audio、storage、analytics
- `Features`
  放 Home、Alarm Setting、Ring、Snooze、Favorites
- `Design System`
  放 glass style、字体、按钮、spacing、transition tokens

HTML prototype 中可以直接迁移的重点：

- `state` 字段设计
- `domain` 规则
- `services` 的接口边界
- 页面流程与交互节奏

HTML prototype 中不能直接迁移的重点：

- DOM 操作
- CSS 动画实现细节
- script 标签加载结构

### Phase 3：iOS MVP 完成后，再规划 Android

Android 不建议与 iOS 同时从零开发，除非团队已经有 2 套稳定执行能力。

更稳妥的顺序是：

1. iOS 先完成 MVP
2. 用 iOS 版本验证真实留存、响铃体验、付费意愿
3. 再决定 Android 是同步复刻，还是做轻量首版

Android 启动前先复盘 3 件事：

- 哪些交互是 iOS 特有表达，Android 需要重设计
- 哪些服务接口已经稳定，可以直接复用规格
- 哪些付费、统计、分享、权限流程需要平台差异化处理

---

## 六、建议的工程边界映射

当前 prototype 到正式 App 的映射建议如下：

| Prototype | 正式 App 对应层 |
|------|------|
| `js/store/state.js` | app state / view model state |
| `js/domain/*.js` | domain / use case / rules |
| `js/services/storage.js` | persistence service |
| `js/services/audio.js` | audio playback service |
| `js/services/weather.js` | weather service |
| `js/services/music-source.js` | music source service |
| `js/ui/*.js` | native UI screens + animation layer |
| `css/styles.css` | design system + screen styles |

原则：

- 规则迁移，不迁移 DOM
- 服务边界迁移，不迁移浏览器实现
- 体验目标迁移，不机械复制 CSS

---

## 七、近期 3 个最值得做的动作

在开始正式 App 之前，最值得继续补的不是更多视觉微调，而是这 3 件事：

1. 把 ring / snooze / dismiss 画成显式状态流  
   这样以后 iOS / Android 不会在边界行为上各写各的

2. 把 service 接口文档化  
   明确 weather、music source、audio、storage 的输入输出和 fallback

3. 补 analytics 事件草案  
   例如：设置闹钟、触发响铃、贪睡、dismiss、收藏、分享、打赏点击

---

## 八、不推荐的路线

以下路线不推荐：

- 把当前 prototype 继续重构成一个“准生产 Web App”
- 在没有冻结核心流程前，就同时开做 iOS 和 Android UI
- 直接复制 CSS 视觉到原生，而不先抽 design token
- 在没有规格文档的情况下，让 iOS / Android 各自解释 prototype

这些做法会让你看似推进很快，实际后期返工更多。

---

## 九、推荐结论

推荐路径是：

1. 继续用当前 HTML prototype 验证交互和核心体验
2. 同步把规则、状态、服务边界文档化
3. 达到稳定阈值后，优先启动原生 iOS MVP
4. iOS 验证通过后，再规划 Android 首版

一句话总结：

**Prototype 负责验证体验，文档负责冻结规则，iOS 负责做成产品，Android 在规则稳定后跟进。**
