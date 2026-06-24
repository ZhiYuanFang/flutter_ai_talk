## ADDED Requirements

### Requirement: Android 12+ 原生 Splash 图标 MUST 按安全区呈现圆形品牌图标
The Android 12+ native splash screen icon SHALL use a dedicated splash asset derived from the same master icon as the desktop app, laid out within the system splash icon safe zone so that the visible result is a filled circular brand icon consistent with Flutter `StartupBrandingIcon`.

在 API 31 及以上，原生 `windowSplashScreenAnimatedIcon` MUST 使用按 Google Splash Icon 安全区（288dp 画布、中心约 2/3 直径有效区）设计的专用 drawable，内容源自与桌面图标同源的 `app_icon_round`；系统遮罩施加后，用户看到的图标 MUST 为圆形填满的品牌图标，不得呈现明显圆角正方形容器或方形留白跳变。

#### Scenario: Android 14 冷启动原生图标为圆形
- **WHEN** 用户在 Android 12 及以上设备冷启动应用
- **THEN** 原生 Splash 阶段的中心图标 MUST 呈现为圆形品牌图标
- **AND** MUST NOT 呈现明显圆角正方形容器包裹图标

#### Scenario: 原生图标与 Flutter 遮罩视觉连续
- **WHEN** 原生 Splash 过渡到 `StartupBrandingOverlay`
- **THEN** 中心图标形状与填满方式 MUST 与 Flutter `ClipOval` + `BoxFit.cover` 展示一致或无明显跳变

#### Scenario: 图标底板与渐变背景融合
- **WHEN** 系统在原生 Splash 绘制图标底板（`windowSplashScreenIconBackgroundColor`）
- **THEN** 底板色 MUST 与启动渐变中间色（`#F7F8FA` 量级）一致，不得出现与背景对比强烈的方形色块
