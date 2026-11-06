## Why

钟点直方图护栏（D）在主候选与回退皆落冷区时会把该根标为不可预测，用户即使近期记录充足也会偶发看到「补充大概多久一次」。产品改为 **先热后软**：仍优先采用落在历史热钟点的候选；若只能保留冷区 `nextAt`，则 **不再拒绝**，在预测卡倒计时上方提示「此刻把握不足」。

## What Changes

- **废止**「直方图护栏与回退皆失败 → 该根不可预测 / 不展示 `nextAt`」作为冷区终态；改为保留最终候选 `nextAt` 并标记钟点把握不足。
- 保留既有回退顺序：主中位（或种子）→ 时长 ≥ 主中位 → 跨自然日；**优先采用通过护栏的热区候选**；仅当无热区候选可接受时，才采用冷区候选并软标。
- 预测结果携带显式「钟点冷区 / 把握不足」信号（不得仅复用样本数 `confidence`）。
- 智能预测热态非预约卡：当该信号为真且展示倒计时时，倒计时区块上方 MUST 显示固定文案「此刻把握不足」；热区候选或未启用护栏时 MUST NOT 显示。
- 有 `nextAt` 后仍按既有规则隐藏「补充大概多久一次」（软标不重新打开该 CTA）。
- **不做**：放宽亲和带宽、改 7 日窗、改小组件/推送出站策略分层、预约卡文案、设置页调试摘要。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `event-interval-prediction`：历史钟点密度护栏由硬拒终态改为「先热后软」；冷区终态保留 `nextAt` 并标记把握不足。
- `smart-prediction-page`：非预约热态卡在钟点把握不足时于倒计时上方展示「此刻把握不足」。

## Impact

- 代码：`app/lib/data/event_next_predictor.dart`（护栏终态与预测模型字段）；`app/lib/ui/smart_prediction_screen.dart`（倒计时上方文案）；行组装若透传字段则 `smart_prediction_rows` 等。
- 规格：对照基线 `openspec/specs/v2.1.4.md`，并承接已实现的 `predict-interval-tod-affinity-guard`（A 亲和 + D 直方图）语义，改写其「皆失败则不可预测」Scenario。
- 无 Android/iOS 原生、无 Go API 契约变更；Debug 可沿用 `[PredictInterval]`，勿刷全量历史。
