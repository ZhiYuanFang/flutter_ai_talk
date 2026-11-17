## Why

`align-go-free-predict-retire` 已要求预测展示仅用亲和 `nextAt`、无预测走亲和进度，但 D5 仍「降级保留」间隔 sheet / `PredictionRecallSeed` 旁路。产品现要求**硬删**「补充大概多久一次」按钮及其整条种子栈，避免无亲和时仍靠用户填间隔撑假预测，并减少遗留 prefs/旁路干扰算法。

## What Changes

- **BREAKING（客户端 UX）**：删除热态预测卡「补充大概多久一次」心跳钮及「调间隔」入口；删除 per-card 间隔玻璃 Sheet（滚轮 + 思考动画）。
- **BREAKING（数据/算法旁路）**：删除 `PredictionRecallSeed` 持久化、provider、upsert/清种子逻辑；`event_next_predictor` / smart prediction / home widget **不得**再消费 `recallIntervalsByRoot` 间隔旁路。
- **引导**：删除或掏空量身定做 / onboarding 中「大概多久一次」写种子路径；缺口补齐仅保留「补充上一次」（及预约「补充下次」）。
- **无预测态**：继续亲和进度条（`predict-affinity-progress`），**不得**再用种子倒计时冒充预测。
- **清理**：遗留 prefs key `prediction_recall_seeds_v1` 可在 wipe/启动时 remove；删除无引用的 dart 文件。
- **保留**：「补充上一次」、预约「补充下次」、推演开关、亲和预测与进度。

## Capabilities

### New Capabilities

- `retire-interval-recall-seed-stack`：硬删间隔回忆 CTA / Sheet / 种子栈 / 预测旁路的规范性约束。

### Modified Capabilities

- `smart-prediction-page`：卡面不得再出现间隔补充 CTA；无 nextAt 仅亲和进度。
- `prediction-recall-per-card-interval`：相关要求作废（REMOVED 或由 retire  supersede）。
- `prediction-recall-seeds`：种子持久化与 predictor 旁路作废。
- `prediction-interval-sheet-thinking`：间隔 Sheet 思考态作废。
- `prediction-recall-onboarding`：补齐路径不得再依赖「补充大概多久一次」；引导内间隔写种子删除。
- `prediction-recall-pickers`：若仅服务间隔滚轮则作废；若仍被「补充上一次」等复用则收窄。

### Superseded（相对 align-go D5）

- `align-go-free-predict-retire` 中「冷启动大概多久一次可作可选 fallback」作废；以本变更为准硬删。

## Impact

- **Flutter**：`smart_prediction_screen.dart`（CTA/`_onPickIntervalRecall`/调间隔）、`prediction_recall_interval_picker.dart`、`prediction_recall_seed*.dart`、`prediction_recall_seed_store.dart`、`prediction_recall_provider.dart`、`prediction_recall_onboarding_panel.dart`、`event_next_predictor` / `smart_prediction_rows` / `smart_prediction_provider` / `home_widget_sync` 的 `recallIntervalsByRoot`、wipe/shell 对种子的清理。
- **无 Go API 变更**。
- **风险**：曾依赖种子倒计时的用户冷启后仅见进度条，直到真实记录够亲和产出 nextAt——符合产品方向。
