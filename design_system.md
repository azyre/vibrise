# Vibrise Design System

> 版本：v1.0  
> 更新日期：2026-02-25  
> 适用范围：iOS App（SwiftUI）所有页面  
> 代码参照：`ios/Vibrise/Vibrise/Core/DesignSystem/DesignTokens.swift`

---

## 一、设计哲学

Vibrise 是一个每天只用一分钟的 App。设计的首要目标是**不打扰**——用户在半梦半醒时与它交互，所有视觉元素必须柔和、克制、直觉化。

### 核心原则

| 原则 | 含义 | 反面例子 |
|------|------|---------|
| **暗色优先** | 深色背景，不刺眼 | 白色背景、高亮度页面 |
| **玻璃质感** | 半透明毛玻璃，层次分明 | 纯色实底卡片 |
| **环境驱动** | 背景随天气/温度/时间变化 | 固定不变的静态背景 |
| **极简交互** | 一个动作完成一件事 | 多步骤弹窗确认 |
| **文字克制** | 能用一行说完就不用两行 | 长段落说明文字 |

---

## 二、色彩系统

### 2.1 基础色

所有颜色基于白色 + 不同透明度，不使用彩色 UI 元素（彩色仅出现在天气背景中）。

| Token | 值 | SwiftUI | 用途 |
|-------|-----|---------|------|
| `primaryText` | `#FFFFFF` | `Color.white` | 主文本 |
| `secondaryText` | `#FFFFFF 60%` | `Color.white.opacity(0.60)` | 副文本（歌手名、提示） |
| `tertiaryText` | `#FFFFFF 32%` | `Color.white.opacity(0.32)` | 弱文本（非激活日期） |
| `surface` | `#FFFFFF 8%` | `Color.white.opacity(0.08)` | 卡片/按钮填充 |
| `surfaceBorder` | `#FFFFFF 12%` | `Color.white.opacity(0.12)` | 卡片/按钮边框 |
| `surfacePressed` | `#FFFFFF 18%` | `Color.white.opacity(0.18)` | 按钮按下状态 |
| `backgroundTop` | `rgb(13, 13, 23)` | `Color(red:0.05, green:0.05, blue:0.09)` | 默认背景渐变起点 |
| `backgroundBottom` | `rgb(26, 20, 36)` | `Color(red:0.10, green:0.08, blue:0.14)` | 默认背景渐变终点 |

### 2.2 天气驱动背景色

首页和响铃页的背景随天气动态变化。每种天气对应一组：基础渐变色 + 2-3 个辅色光球。

| 天气 | 色调倾向 | 情绪 |
|------|---------|------|
| 晴 ≥30°C | 橙红 | 炎热 |
| 晴 20-30°C | 暖黄琥珀 | 温暖 |
| 晴 10-20°C | 青蓝 | 清爽 |
| 晴 0-10°C | 冷蓝 | 凉冷 |
| 晴 <0°C | 灰蓝 | 寒冷 |
| 多云/阴天 | 灰蓝紫 | 沉静 |
| 雾 | 暗灰 | 朦胧 |
| 毛毛雨/小雨 | 蓝灰 | 柔和 |
| 大雨 | 深蓝 | 厚重 |
| 雪 | 银蓝 | 宁静 |
| 雷暴 | 深紫 | 戏剧性 |

实现参照：`HomeBackgroundStyle.swift` → `paletteForWeather()`

### 2.3 时间驱动亮度

页面整体亮度和饱和度随时间变化，模拟自然光照周期。

```
daylightFactor = 0.5 + 0.5 × cos((hour - 12) × π / 12)

brightness = 0.5 + 0.7 × daylightFactor
saturation = 0.68 + 0.08 × daylightFactor
```

| 时间 | 效果 |
|------|------|
| 午夜 | 最暗、最低饱和度 |
| 正午 | 最亮、最高饱和度 |
| 早晨/傍晚 | 中等 |

### 2.4 禁用色

| 不要用 | 原因 |
|--------|------|
| Bootstrap 蓝 `#007bff` | 廉价感 |
| 纯红色 `#FF0000` | 过于警告 |
| 高饱和荧光色 | 刺眼，与暗色主题冲突 |
| 纯黑 `#000000` | 过于死板，用 `rgb(13,13,23)` 替代 |

---

## 三、字体系统

### 3.1 字体选择

| 字体 | 角色 | 来源 | 许可 |
|------|------|------|------|
| **Maven Pro** | Logo、品牌标题、大数字 | Google Fonts | OFL |
| **Satoshi Variable** | 正文、按钮、UI 文案 | Fontshare | Free for commercial use |

### 3.2 Maven Pro 规则

用于：App 名称、闹钟时间数字、倒计时数字、分享卡片品牌字。

| 属性 | 值 | 说明 |
|------|-----|------|
| line-height | **100%** | 始终，无例外 |
| letter-spacing | **-4%** of font size | 始终，如 48pt → tracking = -1.92 |
| font-weight | Regular (400) | 不使用 Bold |

```swift
Text("07:30")
    .font(DesignTokens.Typography.mavenProFont(size: 72))
    .tracking(DesignTokens.Typography.tracking(for: 72))
```

### 3.3 Satoshi Variable 规则

用于：所有非标题文本。

| 属性 | 值 |
|------|-----|
| line-height（< 20pt） | **150%** |
| line-height（≥ 20pt） | **120%** |
| font-weight | Regular (400) 或 Medium (500) |

```swift
Text("Wake up delighted")
    .font(DesignTokens.Typography.satoshiFont(size: 16))
    .lineSpacing(DesignTokens.Typography.satoshiLineSpacing(for: 16))
```

### 3.4 文字层级

| 名称 | 字体 | 大小 | 权重 | 颜色 | 用途 |
|------|------|------|------|------|------|
| Display | Maven Pro | 72pt | Regular | primaryText | 响铃时间、贪睡倒计时 |
| Title | Maven Pro | 64pt | Regular | primaryText | 闹钟卡片时间 |
| Logo | Maven Pro | 48pt | Regular | primaryText | App 标题 "Vibrise" |
| Heading | Satoshi | 32pt | Medium | primaryText | 页面标题（收藏、分享） |
| Body | Satoshi | 16pt | Regular | primaryText | 正文、按钮文案 |
| Body Secondary | Satoshi | 16pt | Regular | secondaryText | 歌手名、副信息 |
| Caption | Satoshi | 14pt | Medium | primaryText | Toast 提示 |
| Label Small | Satoshi | 13pt | Regular | primaryText | 小按钮文字 |
| Day Label | Satoshi | 12pt | Regular | tertiaryText | 日期选择器非激活态 |

### 3.5 文案风格

| 规则 | 示例 |
|------|------|
| 使用 **sentence case**（首字母大写） | "Until next ring"，不是 "until next ring" |
| 全 App 统一，不混用大小写风格 | — |
| 按钮文案简短，不超过 4 个单词 | "Save"、"Cancel Snooze" |
| 不使用感叹号 | "Thanks for the coffee"，不是 "Thanks!" |
| 中英双语 UI 需同时定义 | — |

---

## 四、玻璃/材质系统

Vibrise 的 UI 组件统一使用 glassmorphism（毛玻璃）风格。

### 4.1 模糊层级

| Token | 值 | 用途 |
|-------|-----|------|
| `glass-blur-surface` | 20px | 卡片、按钮 |
| `glass-blur-overlay` | 40px | 全屏覆盖层（贪睡、分享、设置） |
| `glass-blur-background` | 50px | 天气背景底图模糊 |
| `glass-blur-loading` | 16px | 加载状态 |

### 4.2 饱和度

| Token | 值 | 用途 |
|-------|-----|------|
| `glass-saturate-surface` | 1.5 | 卡片、按钮 |
| `glass-saturate-background` | 1.4 | 天气背景 |
| `glass-saturate-loading` | 1.2 | 加载状态 |

### 4.3 SwiftUI 实现

```swift
// 玻璃表面（按钮、卡片）
.background(.ultraThinMaterial)
.background(DesignTokens.Colors.surface)
.overlay {
    RoundedRectangle(cornerRadius: radius, style: .continuous)
        .stroke(DesignTokens.Colors.surfaceBorder, lineWidth: DesignTokens.Border.regular)
}

// 全屏覆盖层
Color.black.opacity(0.4)
    .background(.ultraThinMaterial)
    .ignoresSafeArea()
```

### 4.4 噪点纹理

HTML 原型中使用 SVG 噪点纹理叠加 `mix-blend-mode: overlay`，增加质感。iOS 端可选择性实现（性能优先时可省略）。

---

## 五、间距与布局

### 5.1 间距 Token

| Token | 值 (pt) | 用途 |
|-------|---------|------|
| `screenPadding` / `pageHorizontal` | 24 | 所有页面水平内边距，无例外 |
| `pageTop` | 28 | 页面顶部到第一个内容的距离 |
| `pageBottom` | 32 | 页面底部安全距离 |
| `headerToContent` | 60 | 标题区域到主要内容的间距 |
| `xSmall` | 8 | 紧凑间距（图标组、控件间） |
| `small` | 12 | 卡片之间 |
| `medium` | 16 | 通用间距 |
| `large` | 20 | 列表项间、收藏列表 |
| `xLarge` | 32 | 大块区域分隔 |
| `hero` | 60 | 英雄区域间距 |

### 5.2 圆角

| Token | 值 (pt) | 用途 |
|-------|---------|------|
| `card` | 24 | 闹钟卡片、时间选择器高亮 |
| `media` | 16 | 媒体容器 |
| `track` | 22 | 音轨信息区 |
| `thumbnail` | 12 | 专辑封面缩略图 |
| `pill` | 999 (Capsule) | 按钮、Toast、底栏操作 |

### 5.3 边框

| Token | 值 (pt) | 用途 |
|-------|---------|------|
| `glassThin` | 0.33 | 极细玻璃边框 |
| `regular` | 1 | 标准边框 |

### 5.4 尺寸

| Token | 值 (pt) | 用途 |
|-------|---------|------|
| `iconButton` / `toolbarButton` / `closeButton` | 48 | 圆形图标按钮 |
| `primaryButtonHeight` / `primaryActionHeight` | 60 | 主要操作按钮高度 |
| `toastHeight` | 40 | Toast 提示高度 |
| `dayChip` | 28 | 闹钟卡片中的星期标记 |
| `dayPicker` / `weekdaySelector` | 44 | 设置页中的星期选择按钮 |
| `wheelWidth` / `pickerWidth` | 140 | 时间选择器列宽 |
| `wheelHeight` / `pickerHeight` | 180 | 时间选择器列高 |
| `iconSmall` | 18 | 小图标 |
| `iconMedium` / `bodyIcon` | 20 | 正文中图标 |
| `iconLarge` / `modalCloseIcon` | 24 | 大图标、关闭按钮图标 |

---

## 六、组件库

### 6.1 玻璃圆形按钮（GlassCircleButton）

用于：关闭按钮、底栏图标按钮、响铃页打赏按钮。

```
┌─────┐
│  ×  │  48×48pt，圆形
└─────┘
背景：surface (8% 白) + ultraThinMaterial
边框：surfaceBorder (12% 白), 1pt
按下：surfacePressed (18% 白)
```

实现：`GlassComponents.swift` → `GlassCircleButton`

### 6.2 玻璃胶囊按钮

用于：保存闹钟、取消贪睡、分享操作。

```
┌──────────────────────────┐
│         Save             │  高度 60pt，Capsule 形状
└──────────────────────────┘
背景：surface + ultraThinMaterial
边框：surfaceBorder, 1pt
文字：Satoshi 16pt Medium, primaryText
按下：surfacePressed
```

实现：`GlassComponents.swift` → `glassCapsuleChrome()` modifier

### 6.3 闹钟卡片（AlarmCard）

```
┌────────────────────────────────────┐
│  Test ▷                    ○───    │  顶部：测试按钮 + 开关
│                                    │
│                                    │
│  07:30                             │  Maven Pro 64pt
│  M  T  W  T  F  S  S              │  星期标记 28×28pt
└────────────────────────────────────┘
圆角：24pt
背景：surface + backdrop-filter blur(20px)
边框：surfaceBorder, 1pt
间距：padding 20pt
```

### 6.4 时间选择器（TimePicker）

```
┌─────────┐       ┌─────────┐
│         │       │         │
│   06    │       │   25    │
│  [07]   │   :   │  [30]   │   高亮行：玻璃背景 + 边框
│   08    │       │   35    │
│         │       │         │
└─────────┘       └─────────┘
列宽：150pt
列高：320pt
圆角：24pt
高亮区：76pt 高，玻璃背景
分隔符：Maven Pro 48pt
数字：Maven Pro 36pt
```

### 6.5 开关（Toggle）

```
┌────────────────┐
│    ┌────────┐  │   宽 64pt，高 28pt
│    │  knob  │  │   knob: 39×24pt, 白色, 圆角 12pt
└────────────────┘
背景：rgba(0,0,0,0.4) + mix-blend-mode: soft-light
ON 状态：knob translateX(21pt)
```

### 6.6 Toast 提示

```
┌─────────────────────────┐
│    Alarm saved           │  高度 40pt, Capsule
└─────────────────────────┘
背景：black 28% + ultraThinMaterial
文字：Satoshi 14pt Medium
边框：surfaceBorder, 1pt
显示时长：1400ms 后自动消失
```

实现：`ToastSupport.swift` → `GlassToastView`

### 6.7 感谢覆盖层（ThanksOverlay）

打赏成功后的全屏反馈。

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│            Thanks ☕                 │  Maven Pro 72pt
│                                     │
│                                     │
└─────────────────────────────────────┘
背景：black 55%
文字动画：opacity 0→1 + translateY(12→0)
显示后自动消失
```

实现：`ThanksOverlayView.swift`

### 6.8 空状态卡片（EmptyStateCard）

```
┌─────────────────────────────────────┐
│                                     │
│         Your first alarm            │  Satoshi 24pt Medium
│         Tap + to create one         │  Satoshi 15pt, secondaryText
│                                     │
└─────────────────────────────────────┘
高度：220pt
圆角：24pt
背景：surface
边框：surfaceBorder, 1pt
```

实现：`EmptyStateCard.swift`

---

## 七、覆盖层（Overlay）系统

所有浮层使用统一的进出动画和背景样式。

### 7.1 覆盖层背景

| 类型 | 背景 | 模糊 |
|------|------|------|
| 设置页 | `rgba(0,0,0,0.4)` | blur(40px) |
| 收藏页 | `rgba(0,0,0,0.4)` | blur(40px) |
| 贪睡页 | `rgba(0,0,0,0.4)` | blur(40px) |
| 分享页 | `rgba(0,0,0,0.26)` | blur(40px) |
| 感谢反馈 | `rgba(0,0,0,0.44)` | blur(40px) |

### 7.2 进出动画

```
进入：opacity 0→1 + scale(1.02)→scale(1)
退出：opacity 1→0 + scale(1)→scale(1.02)
时长：0.4s
缓动：cubic-bezier(0.4, 0, 0.2, 1)
```

### 7.3 关闭按钮

所有覆盖层右上角统一使用 `GlassCircleButton`，位置固定：`top: 62pt, right: 24pt`。

---

## 八、动效系统

### 8.1 动效 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `duration-structural` | 0.4s | 页面切换、覆盖层进出 |
| `duration-content` | 0.25s | 内容变化、按钮悬停 |
| `duration-content-emphasis` | 0.35s | 开关切换、重要状态变化 |
| `duration-content-fast` | 0.2s | 图标切换 |
| `duration-media` | 0.6s | 专辑封面淡入 |
| `duration-media-long` | 0.8s | 天气背景渐变 |

### 8.2 缓动曲线

| 名称 | 值 | 用途 |
|------|-----|------|
| standard | `cubic-bezier(0.4, 0, 0.2, 1)` | 大多数过渡 |
| soft | `ease` | 背景、媒体渐变 |

### 8.3 按下反馈

所有可交互元素统一使用：
- 背景色变为 `surfacePressed`（18% 白）
- 不使用缩放动画（保持克制）

### 8.4 背景光球动画

首页天气背景上叠加 3-4 个渐变光球（orb），使用 `will-change: transform` 做缓慢飘动动画。

---

## 九、图标系统

### 9.1 iOS App 使用 SF Symbols

| 用途 | SF Symbol 名称 |
|------|---------------|
| 添加闹钟 | `plus` |
| 关闭/返回 | `xmark` |
| 收藏（空心） | `heart` |
| 收藏（实心） | `heart.fill` |
| 分享 | `square.and.arrow.up` |
| 贪睡 | 自定义 SVG（zzz） |
| 打赏/咖啡 | 自定义 SVG（coffee） |

### 9.2 图标尺寸

| Token | 尺寸 | 用途 |
|-------|------|------|
| `iconSmall` | 18pt | 小图标 |
| `iconMedium` / `bodyIcon` | 20pt | 正文行内图标 |
| `iconLarge` / `modalCloseIcon` | 24pt | 按钮内图标、关闭 × |

---

## 十、分享卡片设计

分享卡片是独立的图片渲染，不受 App 页面约束。

### 10.1 尺寸

| 属性 | 值 |
|------|-----|
| 宽 | 1080px |
| 高 | 1352px |
| 比例 | ≈ 4:5 |

### 10.2 布局

```
┌──────────────────────────────────────────┐
│                                          │
│  (110, 110)                              │
│    ┌──────────────────┐                  │
│    │                  │                  │
│    │    专辑封面       │  550×550, r=44   │
│    │                  │                  │
│    └──────────────────┘                  │
│                                          │
│  (110, 693) Song Title                   │  Satoshi 44pt
│  (110, 759) Artist Name                  │  Satoshi 44pt, 20% 白
│                                          │
│                                          │
│                                          │
│  (110, bottom-99)      (right-110, bottom-99)
│    Feb                     Vibrise       │  Maven Pro 99pt
│    25                                    │  Satoshi 44pt
│                                          │
└──────────────────────────────────────────┘

背景：
  - 专辑封面模糊（blur 160px, brightness 0.6）
  - 3 层径向渐变色晕（bloom）
  - 整体暗色调
```

### 10.3 色晕（Bloom）

分享卡片背景使用 3 个径向渐变色晕，颜色可以从专辑封面主色提取或使用预设：

```css
--share-bloom-1: 116, 160, 224;  /* 蓝 */
--share-bloom-2: 88, 198, 168;   /* 青 */
--share-bloom-3: 228, 160, 92;   /* 琥珀 */
```

实现参照：`styles.css` → `.share-card`

---

## 十一、底栏设计

首页底部固定栏，三个元素：

```
┌───────────────────────────────────────────┐
│  ♡         ☕ Buy me a coffee          +  │
│  (收藏)      (打赏,仅免费版)        (添加) │
└───────────────────────────────────────────┘
位置：底部安全区上方
间距：padding 16pt 24pt 32pt
```

| 元素 | 组件 | 尺寸 |
|------|------|------|
| 收藏按钮 | GlassCircleButton | 48×48 |
| 打赏按钮 | GlassCapsule | 48pt 高, pill 形 |
| 添加按钮 | GlassCircleButton | 48×48 |

---

## 十二、MVP 页面清单与设计要素

### P0 页面

| 页面 | 关键设计要素 | 状态 |
|------|------------|------|
| **闹钟列表首页** | 天气驱动背景 + 光球 + 闹钟卡片列表 + 底栏 | ✅ 原型已有 |
| **创建/编辑闹钟** | 全屏覆盖层 + 时间选择器 + 星期选择 + 保存按钮 | ✅ 原型已有 |
| **响铃页面** | 天气背景 + 大字时间 + 专辑封面 + 歌曲信息 + 收藏/分享按钮 + 贪睡/关闭交互区 + 打赏入口 | ✅ 原型已有 |
| **分享卡片** | 1080×1352 图片生成 + 专辑封面 + 歌曲信息 + 日期 + 品牌 | ✅ 原型已有 |
| **贪睡倒计时** | 全屏覆盖层 + 大字倒计时 + 取消按钮 | ✅ 原型已有 |

### P1 页面

| 页面 | 关键设计要素 | 状态 |
|------|------------|------|
| **收藏列表** | 全屏覆盖层 + 歌曲列表（封面+歌名+歌手） | ✅ 原型已有 |
| **分享操作页** | 全屏覆盖层 + 卡片预览 + 分享/保存按钮 | ✅ 原型已有 |
| **设置页** | 贪睡时长选择 + 打赏入口 + 关于信息 | 需设计 |
| **付费墙** | 功能对比 + 月/年价格卡片 + CTA 按钮 | 需设计 |

---

## 十三、关键约束与规则

### 必须遵守

1. **所有数值使用 `DesignTokens` 常量**，绝不硬编码
2. **所有页面水平内边距 = 24pt**，无例外
3. **Maven Pro 必须带 tracking = fontSize × -0.04**
4. **Satoshi 必须带 lineSpacing**（< 20pt 用 150%，≥ 20pt 用 120%）
5. **新增间距/尺寸先添加到 `DesignTokens`，再引用**
6. **按钮按下状态统一使用 `surfacePressed`**
7. **覆盖层关闭按钮位置固定：top 62pt, right 24pt**

### 禁止事项

1. 不使用纯黑 `#000000` 做背景（用 `backgroundTop` 替代）
2. 不使用彩色 UI 元素（彩色仅限天气背景）
3. 不使用 Bold weight 的 Maven Pro
4. 不使用蓝色系 UI 按钮（Bootstrap 风格）
5. 不在按下反馈中使用缩放动画
6. 不混用大小写风格（统一 sentence case）
7. 不使用感叹号结尾的文案

---

## 十四、实现参照文件索引

| 文件 | 内容 |
|------|------|
| `DesignTokens.swift` | 所有设计 Token（颜色、字体、间距、圆角、尺寸、边框、动效） |
| `GlassComponents.swift` | 玻璃圆形按钮、玻璃胶囊按钮、Toast |
| `VibriseScreenBackgroundView.swift` | 默认页面背景渐变 |
| `HomeBackgroundStyle.swift` | 天气驱动背景色板 + 亮度曲线 |
| `EmptyStateCard.swift` | 空状态卡片组件 |
| `ThanksOverlayView.swift` | 打赏感谢覆盖层 |
| `ToastSupport.swift` | Toast 显示与自动消失逻辑 |
| `ios-design-system.mdc` | Cursor Rule（AI 编码时自动加载的设计规则） |
| `styles.css` | HTML 原型完整样式（可视化参考） |
