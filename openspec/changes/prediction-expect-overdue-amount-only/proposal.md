## Why

预测热态卡目前只要胜出 expect 就在倒计时上方展示「预计约…」（duration 用时与 amount 用量一视同仁）。产品希望：**卡上不再展示下次用时（duration expect）**；**下次用量（amount expect）仅在倒计时已超时态展示**，避免未到期时信息噪音。计时中「预计还要多久结束」行保持不变。

## What Changes

- 热态预测卡次级文案：`expectKind == duration` 时 **MUST NOT** 渲染卡上「预计约…」用时行（仍可在内存/pending 中保留 expect 数据，仅 UI 不展示）。
- `expectKind == amount` 时：仅当该卡倒计时处于 **已超时（overdue）** 才展示「预计约…用量」；未超时 MUST NOT 展示。
- 计时中紧凑卡的 `activeEtaLabel`（预计结束）**MUST NOT** 因本变更改动。
- 横/竖屏凡走同一 `expectLabel` / 倒计时上方 expect 路径的，规则一致。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：收窄「胜出 expect 次级文案」展示条件（隐藏 duration；amount 仅 overdue）。

## Impact

- UI：`smart_prediction_screen.dart` 中 `expectLabel` 计算（及依赖 `formatPredictionExpectCardLabel` 的调用方）。
- 预测引擎 / pending PUT：默认 **不改** expect 计算与上报（仅展示门闩）；若后续要减少噪音字段可另开 change。
- 与 `predict-expect-amount-duration` / `predict-expect-one-exclude-layout` 中「有胜出即展示」冲突处，以本 change 为准更新 delta。
