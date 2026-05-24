## Why

当前冷启动 Flutter 品牌遮罩包含 Logo 心跳动画与标语 Reveal 动画，最短展示 2.4s 后再淡出，用户感知启动偏慢。产品希望去掉启动页动画，缩短品牌遮罩停留时间至 **300ms**，更快进入主页，同时保留静态 Logo 与标语的品牌识别。

## What Changes

- **移除启动动画**：`StartupBrandingOverlay` 不再使用 `SplashLogoPulse` 心跳缩放/光晕与 `StartupTaglineReveal` 渐显动画；改为静态 Logo + 静态标语布局。
- **缩短最短展示时长**：`kMinStartupBrandingDisplay` 由 2400ms 改为 **300ms**；冷启动路由跳转仍与 `ColdStartBootstrap` 并行，取 **max(本地 bootstrap 完成, 300ms)** 后再 `go` 目标路由。
- **去掉遮罩淡出动画**：移除 `AnimatedOpacity` 350ms 淡出；满足时序后直接移除遮罩，即时进入主页。
- **清理无用组件/常量**：删除或内联不再使用的动画 Widget 与相关 duration 常量（如 `kStartupTaglineRevealDuration`）。
- **不改动**：原生 Android/iOS Launch Screen、`ColdStartBootstrap` 本地门禁逻辑、登录后进主页前的 history.length 历史/事件目录 bootstrap（仍按现有 `app.dart` 流程）。

## Capabilities

### New Capabilities

- `startup-splash-static-300ms`：Flutter 冷启动品牌遮罩的静态视觉、300ms 最短展示、无动画淡出及与 bootstrap 时序协同。

### Modified Capabilities

- `cold-start-splash`（变更 `openspec/changes/cold-start-fast-splash/specs/cold-start-splash/spec.md` 语义）：补充 Flutter 全屏遮罩最短展示 300ms、不得依赖 Logo/标语动画作为品牌展示手段；与既有「本地门禁后进主页」决策一致。
- `startup-branding-tagline`（变更 `openspec/changes/startup-branding-tagline/` 语义）：标语保留文案「最懂你的胖宝」，**取消** 1.5s Reveal 动画要求，改为静态展示。

## Impact

- `app/lib/app.dart`：遮罩移除逻辑（去掉 opacity 动画链）。
- `app/lib/ui/startup_branding.dart`：最短展示 300ms；删除淡出/标语动画常量。
- `app/lib/ui/widgets/splash_logo_pulse.dart`：简化为静态 `StartupBrandingOverlay`（或拆分独立文件）。
- `app/lib/ui/widgets/startup_tagline_reveal.dart`：删除或改为静态 Text。
- 无 API、后端或依赖变更。

**Out of scope**：原生启动页、首页历史缓存策略、登录页行为。
