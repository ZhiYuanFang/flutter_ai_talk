## ADDED Requirements

### Requirement: Live visible pushes SHALL expose bizType to the notification tap

For visible (non-silent) pushes on channels that are already in production use (APNs and HMS), the push-service MUST place `bizType` where the client tap callback can read it. APNs MUST include `bizType` in the notification payload delivered as `userInfo`. HMS MUST include `bizType` in the click Intent extras that the Android push plugin enumerates; storing it only inside a data blob that the tap path does not surface is not sufficient. Silent badge pushes MUST NOT be required to support tap routing. The register API allowlist MUST remain `apns`, `hms`, and `mipush`. 已上线的 APNs 与 HMS 可见推送 **必须** 让点击回调读到 `bizType`；静默推送不要求点击路由；register 白名单 **不得** 因此扩大。

#### Scenario: APNs visible push includes bizType

- **WHEN** push-service 经 APNs 发送 `bizType` 为 `ucg_alert` 或 `predict_imminent` 的可见通知
- **THEN** 通知 payload MUST 含该 `bizType`，且用户点击后 iOS MUST 能把该字段交给 Flutter

#### Scenario: HMS tap extras include bizType

- **WHEN** push-service 经 HMS 发送上述可见通知且用户点击通知
- **THEN** 打开应用的 Intent extras MUST 含可解析的 `bizType`
- **AND** 若默认 click action 不能把该字段带入 extras，发送侧 MUST 改用能带入 extras 的 click intent

#### Scenario: Silent badge is not a tap target

- **WHEN** 发送的是 `ucg_silent_badge`
- **THEN** 系统 MUST NOT 为此增加可见通知条或点击路由字段要求

### Requirement: Unpublished vendor channels SHALL be placeholders only

The push dispatcher MUST reserve sender slots for vivo and oppo that log and skip without calling vendor APIs. The system MUST NOT add vivo or oppo to the push register allowlist in this change, and the Flutter client MUST NOT register tokens for those manufacturers. This change MUST NOT require a Xiaomi click payload and MUST NOT treat Xiaomi delivery or tap routing as an acceptance criterion. vivo 与 oppo **必须** 仅为跳过式占位；本变更 **不得** 把它们纳入 register，也 **不得** 把小米点击作为验收。

#### Scenario: Vivo or oppo send is a no-op

- **WHEN** dispatcher 选中 vivo 或 oppo 占位 Sender
- **THEN** 该 Sender MUST 记录日志并跳过
- **AND** MUST NOT 调用对应厂商推送 API

#### Scenario: Register still rejects vivo and oppo

- **WHEN** 客户端以 channel `vivo` 或 `oppo` 调用 push register
- **THEN** 服务端 MUST 拒绝该 channel
- **AND** Flutter 客户端 MUST NOT 为 OPPO 或 VIVO 厂商发起 register
