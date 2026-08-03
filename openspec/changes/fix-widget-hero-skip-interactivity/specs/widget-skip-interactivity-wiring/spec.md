## ADDED Requirements

### Requirement: Android host SHALL register home_widget background components

The Android application manifest MUST declare `es.antonborri.home_widget.HomeWidgetBackgroundReceiver` (exported, intent-filter action `es.antonborri.home_widget.action.BACKGROUND`) and `es.antonborri.home_widget.HomeWidgetBackgroundService` (with `BIND_JOB_SERVICE` permission) so that widget「跳过」background broadcasts can start the Flutter interactivity callback. Android 应用 Manifest **必须** 声明 `HomeWidgetBackgroundReceiver`（exported，action `BACKGROUND`）与 `HomeWidgetBackgroundService`（`BIND_JOB_SERVICE`），使小组件「跳过」后台广播能启动 Flutter 交互回调。

#### Scenario: Manifest 含后台 Receiver 与 Service

- **WHEN** 检查合并后的应用 AndroidManifest
- **THEN** MUST 存在 `HomeWidgetBackgroundReceiver` 与对应 BACKGROUND intent-filter
- **AND** MUST 存在 `HomeWidgetBackgroundService`

#### Scenario: 跳过可触发交互回调

- **WHEN** 已安装含上述组件的构建，且 App 曾冷启并完成 `registerInteractivityCallback`
- **AND** 用户点击 small/large 小组件「跳过」
- **THEN** Dart interactivity 路径 MUST 被调用（可经 Debug 日志 `interactivity skip` 观测）
- **AND** 小组件 hero MUST 按既有 skip 规则更新（有下一预测时前置）

### Requirement: Skip control MUST NOT be the sole launch-app click target conflict

After background wiring is fixed, the「跳过」control MUST retain a dedicated background PendingIntent and MUST NOT rely only on a parent view whose only action is launching the app. 后台接线修复后，「跳过」控件 **必须** 保留独立的后台 PendingIntent，**不得** 仅依赖「唯一动作为打开 App」的父级点击。

#### Scenario: 跳过不依赖整卡打开作为唯一路径

- **WHEN** 用户点击「跳过」
- **THEN** 完成跳过 MUST NOT 以打开前台 App 为唯一必要步骤

### Requirement: iOS skip wiring SHALL keep background intent prerequisites

For iOS builds that include interactive widgets, the project MUST keep (or restore if missing): dual-target `WidgetBackgroundIntent` (or equivalent) calling `HomeWidgetBackgroundWorker`, AppDelegate `setPluginRegistrantCallback` for iOS 17+, and a Widget Extension link against `home_widget` / the Flutter-generated plugin package as required by the integration path (CocoaPods or SPM). 含交互小组件的 iOS 构建 **必须** 保持（缺失则恢复）：双 target 的 `WidgetBackgroundIntent`（或等价）调用 `HomeWidgetBackgroundWorker`、iOS 17+ AppDelegate `setPluginRegistrantCallback`，以及 Extension 按集成路径链接 `home_widget` / Flutter 生成插件包。

#### Scenario: Intent 与插件注册仍在

- **WHEN** 审查 iOS Runner 与 PangbaoWidget 源与 CI target 脚本
- **THEN** AppIntent 源 MUST 属于 Runner 与 Extension（或等价双 target）
- **AND** AppDelegate MUST 在可用系统版本注册 `HomeWidgetBackgroundWorker.setPluginRegistrantCallback`

#### Scenario: Extension 可解析 home_widget

- **WHEN** 构建含「跳过」Button 的 Widget Extension
- **THEN** Extension MUST 能链接/导入 `home_widget`（构建不得因缺少该模块而失败）

### Requirement: Android release build MUST pass after manifest wiring

After adding the background receiver/service declarations, `flutter build apk --release` MUST succeed before merge, and ProGuard keep rules for the background classes MUST remain in effect if R8 would otherwise strip them. 增加后台 receiver/service 声明后，合并前 **必须** `flutter build apk --release` 成功；若 R8 会剥离后台类，ProGuard keep **必须** 继续生效。

#### Scenario: release 构建通过

- **WHEN** 完成本 change 的 Android Manifest 改动
- **THEN** 合并前 MUST 完成 release APK 构建通过
