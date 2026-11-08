## Why

预约预测卡「上一次」行写成 `上一次{事件名}：时间 · 备注`，事件名与标题重复，横向易被截断。同时不限窗 filter 已能展示久远上次，但点按编辑仍只查近窗 `home∪range`，常见「看得见、点不了」。需要缩短文案并让点按稳定进入编辑 sheet。

## What Changes

- 预约瀑布/compact 卡上次发生行：**不再**展示「上一次{事件名}」前缀；仍展示相对时间，非空 history remark 仍以 ` · {remark}` 追加。
- 点按该行 = **编辑意图**：再走一次不限窗 `filter`（或等价 get）拿到真 `HistoryRecord`，成功则打开 `showHomeHistoryEditSheet`；失败 toast/提示，不得假装可编辑。
- 非预约卡文案与现有「仅缓存不开放编辑」规则保持不变。
- **相对基线例外**：预约根点按编辑 **不再**受「仅 tip/缓存、近窗无 record 则 MUST NOT 开 sheet」约束（改为点按时拉取）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `appointment-event-client`：预约卡上次行文案格式；点按再 filter 后开编辑 sheet。
- `event-interval-prediction`：预约根点按「上次行」例外于「仅 tip/缓存、近窗无 record 则不开放编辑」。

## Impact

- UI：`smart_prediction_screen` 预约卡 `lastOccurrenceLabel` 格式；`onEditLastOccurrence` 预约分支改为异步拉取再开 sheet。
- 格式化：`formatPredictionLastOccurrenceLabel`（或预约专用短格式）。
- 数据：复用既有 `GET /device/history/api/filter` + `ignoreTimeRange`；不新增 Go 接口。
- 非预约预测卡、竖列表准确率 chrome、预约 next 备注：不在范围。
