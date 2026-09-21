## ADDED Requirements

### Requirement: iOS notification tap SHALL deliver bizType to Flutter reliably

On iOS, a user tap on a visible remote notification MUST deliver a parseable `bizType` (when present at the APNs userInfo root as a string, per push-service contract) into the same Flutter tap inbox used by Android. The client MUST cover warm taps via the notification-center receive callback and cold starts via both legacy launch options and UIScene connection `notificationResponse` when applicable. If the MethodChannel is not ready at tap time, the client MUST retain the pending `bizType` and MUST expose it to Dart after the handler binds (including a post-bind fetch), and MUST NOT silently discard a known tap solely because the first invoke failed. 在 iOS 上，可见远程通知点击 **必须** 把根级字符串 `bizType`（当载荷含该字段时）送入与 Android 相同的 Flutter 点击收件箱；热点击走通知中心回调，冷启 **必须** 覆盖 launchOptions 与 UIScene `notificationResponse`；channel 未就绪时 **必须** 暂存并在绑定后可被 Dart 拉取，**不得** 因首次 invoke 失败而静默丢弃已知点击。

#### Scenario: Warm tap while already on home UCG page

- **WHEN** 应用已在运行且用户位于主壳 UCG 页，点击通知栏中 `bizType` 为 `predict_imminent` 的可见通知
- **THEN** Flutter 点击收件箱 MUST 记录到该 `bizType`
- **AND** 主壳 MUST 按既有分流切到预测页

#### Scenario: Cold start via UIScene notification response

- **WHEN** 应用进程未运行，用户点击可见通知冷启动，且系统通过 UIScene connection options 提供 `notificationResponse`
- **THEN** 客户端 MUST 从该响应提取并暂存点击载荷中的 `bizType`（若存在）
- **AND** Dart 在绑定通知点击后 MUST 仍能读到该次点击

#### Scenario: Channel not ready on first invoke

- **WHEN** 原生已收到通知点击并解析出 `bizType`，但当时 Flutter MethodChannel 尚未可投递
- **THEN** 原生 MUST 保留 pending `bizType`
- **AND** Dart 在绑定 handler 之后 MUST 能取得该 pending 值并写入收件箱

### Requirement: Push-click delivery failures SHALL toast in release builds

When the client determines that an iOS (or shared) notification-tap handling step failed—including MethodChannel / getInitial errors, or a confirmed tap callback whose payload cannot yield a `bizType` key—the client MUST present an error toast via the existing app toast entry (`showAppToast` or `apiToastProvider`) in **both** debug and release builds. Ordinary app launch with no tap (null initial payload) MUST NOT toast. Successful inbox record and successful home routing MUST NOT toast. 当客户端判定通知点击处理失败（含 channel/getInitial 异常，或已确认的点击回调无法解析出 `bizType` 键）时，**必须** 经既有 Toast 入口在 Debug **与** Release 弹出错误提示；无点击的普通启动 **不得** Toast；成功入收件箱与成功分流 **不得** Toast。

#### Scenario: Parse failure after confirmed tap

- **WHEN** iOS 已确认一次通知点击回调到达 Dart，但载荷无法解析出 `bizType` 键
- **THEN** 客户端 MUST 弹出错误 Toast（Release 包同样弹出）
- **AND** MUST 经 `AppDebugLog.ucgPush`（或既有 ucgPush 日志路径）记录原因

#### Scenario: getInitial or channel error

- **WHEN** Dart 调用 iOS `getInitialNotificationTap`（或等价补拉）抛错，或热点击 channel 投递向 Dart 上报失败
- **THEN** 客户端 MUST 弹出错误 Toast（Release 包同样弹出）

#### Scenario: Normal launch without tap

- **WHEN** 用户普通冷启动且不存在待处理的通知点击 pending
- **THEN** 客户端 MUST NOT 因「初始点击为空」弹出 Toast
