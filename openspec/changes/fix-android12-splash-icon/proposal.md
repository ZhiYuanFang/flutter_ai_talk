## Why

Android 12（API 31）起系统强制使用 SplashScreen API，`launch_background.xml` 的 layer-list 在 Android 14 等设备上不再控制启动图标。当前 `values-v31` 直接将方形 `app_icon_round.png` 作为 `windowSplashScreenAnimatedIcon`，系统会施加圆形/squircle 遮罩，导致冷启动前几帧呈现「圆角正方形」，与 Flutter `StartupBrandingOverlay` 的圆形图标视觉不一致。需按 Google Splash Icon 安全区规范提供专用启动图标资源，使原生阶段与 Flutter 遮罩平滑衔接。

## What Changes

- 新增 Android 12+ 专用启动图标 drawable（`splash_screen_icon`），按 288dp 画布 / 中心 2/3 安全区设计，内容源自与桌面图标同源的 `app_icon_round` 资产。
- 更新 `values-v31/styles.xml`：`windowSplashScreenAnimatedIcon` 指向新资源；`windowSplashScreenIconBackgroundColor` 设为渐变中间色，与背景融合。
- 保留 API 30 及以下 `launch_background.xml` layer-list 路径不变。
- 不改动 `MainActivity.installSplashScreen`、`hideNativeSplash` 时序及 Flutter `StartupBrandingOverlay` 逻辑。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `startup-splash-gradient-visual`：补充 Android 12+ 原生 Splash 图标须按系统安全区呈现圆形品牌图标、与 Flutter 遮罩视觉连续的要求。
- `cold-start-splash`：补充 Android 12+ 原生启动窗口图标不得呈现明显 squircle/方形容器与 Flutter 圆形图标跳变的要求。

## Impact

- **Android 资源**：`app/android/app/src/main/res/drawable/` 新增 `splash_screen_icon.xml`（及必要时 `values/colors.xml` 补充 `splash_icon_background`）。
- **Android 主题**：`app/android/app/src/main/res/values-v31/styles.xml`。
- **Flutter / iOS**：无变更。
- **基线**：引用 `v2.0.2` 中 `startup-splash-gradient-visual`、`cold-start-splash` 并做 delta 扩展。
