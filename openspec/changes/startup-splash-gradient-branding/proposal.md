## Why

当前冷启动 Flutter 遮罩（`StartupBrandingOverlay`）为纯色灰底 `#ECEFF1`，标语使用 `ColorScheme.primary`，与产品参考稿（上粉、下浅青的纵向渐变 + 蓝色标语「最懂你的胖宝」）不一致，且与原生启动页切换时视觉跳跃明显。需要在不延长冷启动阻塞时序的前提下，统一启动页品牌视觉。

## What Changes

- **Flutter 启动遮罩**：背景改为**自上而下**柔和渐变（顶部浅粉 → 中部近白 → 底部浅青），全屏铺满。
- **标语文案**：保持「最懂你的胖宝」；颜色改为**固定品牌蓝**（不随性别主题 primary 变化），字重与字号与现网接近。
- **Logo**：继续使用 `assets/images/splash_logo.png`，居中布局不变。
- **占位路由**：`/splash` 的 `SplashScreen` 背景与遮罩渐变一致，避免遮罩淡出前闪灰底。
- **Android 原生（可选对齐）**：`launch_gradient` + `launch_background`，减轻「原生 → Flutter」色差。
- **事件 logo 启动预热**：冷启动在 `go(/home)` 前对目录 logo 做 `precacheImage`（优先本地文件）；`refreshAndPersist` 合并磁盘 `localLogoPath`，后台下载完成后刷新 provider state。

## Capabilities

### New Capabilities

- `startup-splash-gradient-visual`：冷启动 Flutter 遮罩与占位页的渐变背景、蓝色标语、原生渐变衔接及事件 logo 内存预热约定。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线）与已完成变更 `startup-branding-tagline`、`cold-start-fast-splash` 兼容：仅视觉层调整，不改变 bootstrap 时序。

## Impact

- `app/lib/ui/startup_branding.dart`：渐变色、标语蓝色常量。
- `app/lib/ui/widgets/splash_logo_pulse.dart`：`StartupBrandingOverlay` 背景与文字样式。
- `app/lib/ui/splash_screen.dart`：占位 Scaffold 背景。
- `app/android/app/src/main/res/`、`app/lib/ui/event_logo_startup_warmup.dart`、`event_catalog_store.dart`、`event_catalog_sync.dart`、`event_catalog_notifier.dart`、`app.dart`。
- 无 API、依赖变更。
