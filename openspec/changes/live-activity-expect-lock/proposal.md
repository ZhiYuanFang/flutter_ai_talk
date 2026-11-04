## Why

锁屏 Live Activity 已展示进行中已计时与预测事件名，但缺少「预计结束 / 预计时长或用量」提示。Go twin `live-activity-expect-lock-go` **已完成**：ContentState 透传结构化 expect，Imminent LA 标题改为基句（不含「预计这次约」后缀），active-eta / history update 灌入或保留 `expectEndAt`。本 change 只做 iOS Extension 解码、短文案展示，并把预测右槽字号相对既有 trailing `.title` **减小 5pt**，避免长预计文案抢主标题。

## What Changes

- Timing 锁屏：事件名下方可选副行「预计 HH:mm 结束」（`expectEndAt`）；右侧系统已计时不变、字号保持既有 `.title`。
- Imminent 锁屏：`expectKind` 为 duration/amount 时右侧短版预计文案；**右槽字号 = 既有 trailing `.title` 字号 − 5pt**；无 expect 仍空右槽。
- 解码对齐 Go 已发字段：`expectEndAt` / `expectKind` / `expectDurationSec` / `expectAmount` / `expectUnit`；旧推送兜底。
- 主标题继续展示推送 `title`（Go 已为 `{昵称}要{事件名}了` 基句）；客户端 MUST NOT 再拼「预计这次约」进标题。
- Dynamic Island：**不改**。
- 更新 `LIVE_ACTIVITY.md`；**不实现 Go**（twin 已落地）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-timing-live-activity`：锁屏标题列可选「预计 HH:mm 结束」副行；ContentState 可选 `expectEndAt`。
- `predict-imminent-live-activity`：锁屏右侧短版 expect；右槽字号相对 `.title` −5pt；Island 无 expect。

## Impact

- iOS：`PredictLiveActivityAttributes.swift`、`PredictLiveActivityViews.swift`、`LIVE_ACTIVITY.md`。
- 对端 Go：`live-activity-expect-lock-go` **已完成**（本仓仅对齐契约，不再补 Go 提案）。
- Flutter Dart：无逻辑改动。
