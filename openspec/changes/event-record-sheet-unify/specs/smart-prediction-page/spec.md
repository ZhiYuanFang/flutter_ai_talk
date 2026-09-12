## MODIFIED Requirements

### Requirement: Sparse hot cards SHALL offer heartbeat add-last CTA when forecast enabled and lastAt missing

On a hot (non-demo-skeleton) prediction event card whose forecast is enabled, `prediction` is null, and `lastAt` is null, the card MUST show a full-width event-accent heartbeat control labeled to the effect of「补充上一次」(same heartbeat pattern as「补充大概多久一次」/ in-timer「停止」). Activating it MUST invoke the same **supplement** path as tapping the card: open the unified event-record sheet with intent `supplement` (cross-day time required; see `event-record-sheet`). The client MUST NOT use the plain `add` now-submit path for this CTA or card tap while `lastAt` is null. The client MUST NOT show the interval-recall CTA on that card while `lastAt` is null. When forecast is disabled, the client MUST NOT show「补充上一次」, MUST NOT show the interval CTA, and MUST NOT treat a card tap as the supplement or add fill path.

热态预测卡在推演开启、`prediction == null` 且 `lastAt == null` 时，**必须** 展示心跳「补充上一次」；点击与点卡 **必须** 同为 **supplement** 统一 Sheet（须选跨日时间），**不得** 再走普通加事件 now 路径。`lastAt == null` 时 **不得** 展示间隔回忆 CTA。推演关闭时 **不得** 展示补齐 CTA，且点卡 **不得** 触发补齐。

#### Scenario: 无上次仅补上次心跳

- **WHEN** 热态某根卡 `forecastEnabled == true`、`lastAt == null`、`prediction == null`
- **THEN** 卡 MUST 展示心跳「补充上一次」
- **AND** MUST NOT 展示「补充大概多久一次」
- **AND** 点击「补充上一次」MUST 打开与点该卡相同的 supplement 统一 Sheet

#### Scenario: 关推演无补齐

- **WHEN** 热态某根卡 `forecastEnabled == false`
- **THEN** MUST NOT 展示「补充上一次」
- **AND** MUST NOT 展示「补充大概多久一次」
- **AND** 点卡 MUST NOT 触发加喂养补齐路径

#### Scenario: 补充非量进 Sheet

- **WHEN** 无 lastAt 热态卡对应叶子为 time 或 one，用户点「补充上一次」
- **THEN** 客户端 MUST 打开统一 Sheet 且 MUST NOT 仅用确认框后提交 now
