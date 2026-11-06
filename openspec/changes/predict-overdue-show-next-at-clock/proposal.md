## Why

智能预测卡逾期后大数字停在 `00:00:00`，只说明「已到点」，看不出原先估的是几点。超时后改为展示预估 `nextAt` 的本地时刻，并同步改倒计时区标题，让逾期态仍可读。

## What Changes

- 热态预测卡倒计时区块：当 `nextAt` 已逾期时，大数字 MUST 展示预估时刻（不再固定 `00:00:00`）。
- 时刻格式：落在**本地今天**仅 `HH:mm`（MUST NOT 加「今天」）；昨天为「昨天 HH:mm」；更早为「M月D日 HH:mm」（或与现有「上一次」日文案同级规则）。
- 逾期时标题 MUST 从「距离下次{事件名}倒计时」改为「预计{事件名}时刻」；未逾期保持原标题。
- 旁侧相对文案「已超时」MAY 保留（本 change 不强制改）。
- **不做**：桌面小组件 native overdue 文案、首页 tip 栏相对句、准确率对照卡、改预测算法。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：逾期倒计时大数字与标题改为预估时刻展示。

## Impact

- 代码：`formatPredictionCountdownHms`（或并列格式函数）与 `smart_prediction_screen` 倒计时标题；可能复用/对齐 `formatWidgetLastAt` 的日界规则。
- 规格：对照基线 `openspec/specs/v2.1.4.md` 之 `smart-prediction-page`。
- 无 Android/iOS 原生契约、无 Go API 变更。
