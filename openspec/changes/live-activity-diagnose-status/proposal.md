## Why

真机锁屏通知页在开通超时时常只显示「等待系统 Push-to-Start token 超时，未能完成上报」，会把「系统未吐 token」「token 已到但 HTTP 失败」「只成功一类 attributes」混成同一句话，线上无系统日志时无法定位。需要在现有显态基础上补充更细的阶段结果与可复制诊断摘要，方便客服/研发对照排查。

## What Changes

- 手动重试结束时 MUST 区分并展示失败类别：未收到系统 token、已收到 token 但 `live-activity/register` 失败、仅部分 `attributesKind` 成功、超时但保留上次成功等；禁止用笼统「等 token 超时」覆盖已发生的 HTTP 错误文案。
- 锁屏通知页 MUST 补充排障锚点（至少：iOS 大版本、是否已开始监听、imminent/timing 各自「是否收到过 PTS 事件 / 是否 register 成功」、最近错误阶段码或短标签）；仍 MUST NOT 展示完整 token。
- 原生侧 SHOULD 暴露「本进程是否曾 deliver 过 push_to_start」计数或等价信号，供 Dart 判断「系统是否吐过」vs「Dart 未订阅」。
- 不新增自动 register 触发点；不改 Go API 契约；不改消息通知偏好解耦结论。

## Capabilities

### New Capabilities

- （无）本变更在既有锁屏设置能力上加深诊断，不另立 capability 名。

### Modified Capabilities

- `settings-live-activity`: 强化真机失败分类、分 attributes 结果与可复制诊断摘要，避免超时文案掩盖 HTTP 失败。

## Impact

- Flutter：`LiveActivityRegistrationService` / status 模型、`LiveActivitySettingsScreen`、可选 `PredictLiveActivityBridge` MethodChannel 诊断字段。
- 对照既有 change `settings-live-activity-status`；基线 `openspec/specs/v2.1.4.md`。
- 无 Android/Web 入口变更；无 Go 变更。
