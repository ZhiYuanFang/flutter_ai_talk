## Why

iPhone 点击系统可见通知（`ucg_alert` / `predict_imminent`）无法按 `push-click-home-route` 切页，华为正常；push-service 已有 `send_ok channel=apns … bizType=…`，说明服务端 payload 已带业务类型。根因落在 iOS 点击投递到 Flutter `PushClickInbox` 的管道（含 UIScene 冷启与热路径 MethodChannel）。排查期需要 **正式包也弹出错误 Toast**，便于真机直接感知投递/解析失败。

## What Changes

- 加固 iOS 通知点击 → Dart 收件箱整段投递：热路径（`didReceive`）、冷启（含 Scene `connectionOptions.notificationResponse`）、channel 未就绪时的 pending 补拉。
- Native 优先抽出根级 `bizType` 字符串再交给 Flutter（对齐 Android 稳健性），减少整包 map / 非 String 被丢弃的风险。
- 投递或解析失败时，经既有 `showAppToast` / `apiToastProvider` **在 Debug 与 Release 均弹出错误信息**；成功切页不 Toast。
- 原生侧对 `didReceive` / 冷启入口增加可在 Xcode 控制台看到的打点（无法 Toast 时仍可区分「回调没进」）。
- **不改变** 主壳按 `bizType` 分流规则（预测页 / UCG 消息 Tab / 未登录留预测等）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `push-click-home-route`: 明确 iOS 必须将点击中的 `bizType` 可靠交给 Flutter；投递/解析失败时正式包也须用户可见错误 Toast；冷启须覆盖 UIScene 通知响应入口。

## Impact

- iOS：`AppDelegate.swift`、`SceneDelegate.swift`（通知点击暂存与 channel）。
- Flutter：`ucg_push_native_mobile.dart`、`push_click_inbox.dart`（及必要时 `app.dart` / 主壳消费处的失败上报）。
- 依赖既有 Toast 总线；日志仍走 `AppDebugLog.ucgPush`（禁止裸 `print`）。
- 服务端 / HMS / `push-click-home-route` 分流语义不变；Android 行为保持。
