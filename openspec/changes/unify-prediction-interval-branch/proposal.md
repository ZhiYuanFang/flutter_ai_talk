## Why

本地预测名义上共用 `predictAllUpcoming`，实际靠「回忆种子合成伪 `HistoryRecord`」伪装样本不足路径，导致 `lastAt`/展示/编辑/删空与真喂养分叉（套娃改时间、删光后仍有 countdown）。需要把两套合二为一：统一 `nextAt = lastAt + interval`，仅在间隔取值处分岔，去掉伪历史兼容税。

## What Changes

- **BREAKING（推演输入）**：预测路径 **不得** 再将 `PredictionRecallSeed` 合成为伪 `HistoryRecord` 进入 `predictAllUpcoming` / 行构建；种子降级为「间隔旁路」（持久化形状可保留 `lastAt` 字段，但推演 `lastAt` **不得** 以种子为准）。
- 单一公式：对每个目录根，`nextAt = lastAt + interval`；`lastAt` **必须**仅来自真喂养（home∪range，排除种子）；无真 `lastAt` → **不得**产出预测。
- 间隔分岔：真样本达标 → 既有加权中位；未达标且存在有效种子 → 使用 `seed.interval`；否则无预测。
- 智能预测卡「上一次」展示时刻与可编辑真记录同源；改/删后跟真喂养更新；该 root 真记录清空时 **必须**清除对应种子并回到无记录态（「暂无」/「补充上一次」，无种子 countdown）。
- 删除等 home 乐观更新时 **必须**同步从 `predictionRangeHistory` 快照去掉同 id（或等价 tombstone），避免并集短暂仍「有记录」。
- 本 change **不**要求改时间后重锚种子；**不**恢复量身定做 Dialog；**不**新建 `**/test/**`。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `event-interval-prediction`：统一推演管线；间隔来源分岔；禁止种子伪记录进入间隔统计。
- `smart-prediction-page`：`row.lastAt` 仅真喂养；删空/改时展示与预测态一致。
- `prediction-recall-per-card-interval`：确认间隔后种子仅提供 `interval` 旁路；不再依赖合成发生点喂入 predictor。

## Impact

- **Flutter**：`event_next_predictor.dart`、`smart_prediction_rows.dart`、`prediction_recall_seed.dart`（merge/synthetic 退役或缩为死代码）、`prediction_recall_provider.dart`、`smart_prediction_provider.dart`、`prediction_range_history_provider.dart` / `home_history_notifier` 删除同步、`smart_prediction_screen` CTA 门闸（依赖真 `lastAt`）、小组件 `resolveWidgetPredictionInputs` 等同管线。
- **API / Android**：无契约变更；无 `app/android/**` 必改。
- **基线**：对照 `openspec/specs/v2.1.0.md` 之 `event-interval-prediction`；页面/回忆能力以近期未收版 change（catalog-complete / interval-thinking）行为为准并本变更修正。
- **测试**：不新建 `**/test/**`；手工验收充分样本 / 稀疏+种子 / 改时间 / 删光 / 无真记录。
