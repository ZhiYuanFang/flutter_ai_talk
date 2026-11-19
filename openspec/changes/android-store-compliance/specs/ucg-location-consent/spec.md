## ADDED Requirements

### Requirement: Store release builds MUST NOT ship the geolocator native SDK while UCG location is stubbed

While UCG location is product-disabled (Dart stub / no live GPS), the client MUST NOT depend on the `geolocator` package in `pubspec` for store release builds, and the release APK MUST NOT contain the `com.baseflow.geolocator` native plugin. Call sites MAY keep calling `ensureUcgLocationForDistance` (or equivalent), which MUST return null without requesting location permission or reading coordinates. Re-enabling UCG location MUST restore the SDK, Manifest location permissions, and privacy disclosure before shipping a GPS-enabled build.

在 UCG 定位为桩/未启用期间，上架 release MUST NOT 依赖 `geolocator`，正式 APK MUST NOT 含该原生插件；定位入口 MUST 安全返回 null。重开 UCG 定位前 MUST 恢复 SDK、权限与隐私披露。

#### Scenario: Stub returns null without permission prompt

- **WHEN** 业务调用 UCG 定位入口且定位为发布桩实现
- **THEN** 客户端 MUST 返回 null 坐标
- **AND** MUST NOT 弹出定位用途框或系统定位权限请求

#### Scenario: Release APK has no geolocator plugin

- **WHEN** 对用于上架的 Android release APK 检查插件/类名
- **THEN** MUST NOT 发现 `com.baseflow.geolocator`（或等价 geolocator_android 插件注册）
