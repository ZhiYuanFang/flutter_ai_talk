## Why

预测页横屏常用于投屏到电视，且孩子会长时间注视；用户若选用浅色主题，整屏高亮度壳色在大屏上刺眼。需要在「预测页 + 横屏」时强制暗壳体验，同时保留当前 preset 的主色 tint，回竖屏立即恢复用户原主题。

## What Changes

- 预测页处于横屏时：**一律**应用暗壳视觉（方案 A），不依赖用户当前是浅壳还是暗壳。
- 暗壳派生 **MUST** 保留当前生效 preset / 自定义种子的 **主色 tint**（hue/品牌识别），不得整页硬切到无关的「夜空」或固定灰黑。
- 范围一体覆盖：页壳背景、事件卡/瀑布流 chrome、身份栏、语音 chip、弹幕 toast，以及同页其它经 `AppColor` / tokens 取色的 chrome——横屏子树内视觉一致。
- 回竖屏或离开预测页横屏条件时：**立即**恢复用户原生效主题（含自动夜空调度结果），不得改写持久化 baseline。
- 竖屏预测、其它 Tab/路由横屏不在本变更范围。
- 不新增用户「投屏开关」；无 **BREAKING** API。

## Capabilities

### New Capabilities

- `prediction-landscape-tv-safe-theme`：预测页横屏强制暗壳且保留主色 tint、回竖屏恢复原主题；一体覆盖身份栏 / chip / 弹幕等页内 chrome。

### Modified Capabilities

- （无）基线未收录「预测横屏投屏护眼」要求；沉浸/语音等并行 change 不改本能力语义。

## Impact

- 代码：`smart_prediction_screen.dart`（横屏子树 `Theme` 覆盖或等价）；主题构建复用 `buildAppTheme` / `AppVisualTokens` / `AppColor` 路径；禁止业务内联马卡龙 hex 或私自读 `isDarkShell` 拼色。
- 持久化：`ThemePreferences` / 自动夜空 baseline **不得**被横屏特例写回。
- 规格：新 capability `prediction-landscape-tv-safe-theme`。
- 测试：不新建 `**/test/**`；手工浅色 preset × 横竖旋转 + 弹幕/chip/身份栏一体验收。
