## ADDED Requirements

### Requirement: iOS Live Activity MethodChannel SHALL remain strongly retained for native-to-Dart token delivery

The iOS client MUST keep a strong reference to the Live Activity `FlutterMethodChannel` (`com.fzy.pangbao/live_activity`) for the lifetime of the Flutter engine, in the same family as the existing UCG/APNs push channel. The client MUST NOT rely solely on a `weak` reference assigned from a local `FlutterMethodChannel` that can be deallocated while the messenger name-handler still accepts Dart→native calls. When ActivityKit delivers a Push-to-Start or per-activity token, the native side MUST `invokeMethod` that payload to Dart so the existing listen→register pipeline can run.

iOS 客户端 MUST 对 Live Activity MethodChannel 保持强引用（对齐现有推送 channel）；MUST NOT 仅用局部变量 + weak 导致 Native→Dart 丢失。ActivityKit 吐出 token 时 MUST `invokeMethod` 交给 Dart 走既有 register 管线。

#### Scenario: Push-to-Start reaches Dart after ActivityKit emit

- **WHEN** 已登录 iOS 上 ActivityKit 对 `PredictImminentAttributes` 或 `PredictTimingAttributes` 发出 Push-to-Start token 且 Live Activity channel 已在引擎中注册
- **THEN** 原生 MUST 将该事件经 MethodChannel 送达 Dart
- **AND** Dart MUST 能将该事件计为 `ptsEventSeen`（并在随后尝试 `live-activity/register`）

#### Scenario: Channel must not be only a weak local

- **WHEN** AppDelegate 完成 Live Activity MethodChannel 的创建与 handler 绑定
- **THEN** 至少一处强引用 MUST 持有该 `FlutterMethodChannel` 实例直至引擎重建或显式替换
