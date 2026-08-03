## Why

桌面小组件「跳过」已接 `HomeWidgetBackgroundIntent` 与 Dart 回调，但 Android 宿主未按 home_widget 文档注册 Background Receiver/Service，Broadcast 无落点，点击完全无反应。需补齐注册并核对 iOS 交互链路，避免同类「UI 有按钮、后台接不住」问题。

## What Changes

- Android：在 `AndroidManifest.xml` 注册 `HomeWidgetBackgroundReceiver` 与 `HomeWidgetBackgroundService`（与 home_widget example / 官方 Interactive Widgets 文档一致）。
- Android：评估并必要时收紧 hero 父级整卡 launch 点击，避免抢占「跳过」热区（若仍复现）。
- iOS：核对并固化交互前置条件——`WidgetBackgroundIntent` 双 target、`ForegroundContinuableIntent`、`AppDelegate` 的 `setPluginRegistrantCallback`、Extension 能链接 `home_widget`；CI `ensure_pangbao_widget_target.rb` 补齐缺口（若有）。
- 合并前 Android **必须** `flutter build apk --release` 通过；proguard 已 keep 后台类则复核即可。
- 不改 skip 业务语义（S1、hero 过滤、recent 可含 skip）。

## Capabilities

### New Capabilities

- `widget-skip-interactivity-wiring`：Android/iOS 小组件「跳过」后台交互接线与验收护栏。

### Modified Capabilities

- （无）行为需求仍归属既有 `widget-hero-skip`；本 change 补交付缺口。

## Impact

- `app/android/app/src/main/AndroidManifest.xml`（必改）；可能微调 `PangbaoWidgetRenderer` launch 目标列表。
- iOS：`AppDelegate` / `WidgetBackgroundIntent` / CI ruby / Extension 链接；以核对与小补为主。
- 依赖未归档 `widget-hero-skip-next`；本 change 专修交互通道。
- 用户须重装 App 并至少冷启一次以写入 interactivity callbackHandle。
