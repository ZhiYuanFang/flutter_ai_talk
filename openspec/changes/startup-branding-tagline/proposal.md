## Why

冷启动 Flutter 品牌遮罩目前仅有 Logo 心跳动画，缺少品牌 Slogan 表达。Release 包原生启动已足够快，无需再动原生 Splash；在现有 `StartupBrandingOverlay` 上增加标语「最懂你的胖宝」，可在不改变启动时序的前提下强化品牌感知。

## What Changes

- 在 `StartupBrandingOverlay` 的 Logo 下方增加标语 **「最懂你的胖宝」**。
- 标语在 **1.5s 内** 完成「由小变大、由细变粗、主色由浅到满」的单次动画，之后保持终态直至遮罩淡出（与现有最短展示 2.4s 及淡出逻辑一致）。
- 标语颜色使用当前主题 `ColorScheme.primary`（随宝宝性别主题变化）。
- 不修改原生 Android Splash、`kMinStartupBrandingDisplay` 时长及 `ColdStartBootstrap` 流程。

## Capabilities

### New Capabilities

- `startup-branding-tagline`：冷启动 Flutter 遮罩标语文案、布局、1.5s Reveal 动画及与 Logo 心跳/淡出的协同。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线；与 `cold-start-fast-splash` 的启动时序决策兼容，仅扩展 Flutter 遮罩视觉层。）

## Impact

- `app/lib/ui/widgets/splash_logo_pulse.dart`（或拆分新组件）：`StartupBrandingOverlay` 布局与动画。
- `app/lib/ui/startup_branding.dart`：标语常量（可选动画时长常量）。
- 无 API、后端或依赖变更。

**Out of scope**：原生启动页优化、登录页 autofocus、首页历史缓存。
