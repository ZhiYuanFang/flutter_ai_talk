## Why

预测卡「补充大概多久一次」确认后立刻关 Sheet，用户感受不到系统在为其节奏推演；量身定做 Dialog 已有打字机思考叙事，但 per-card 路径未复用。需要在**同一间隔 Sheet 内**于确认后播放思考过程，强化「认真推理」感知，并说明当前预测会随后续喂养自动修正。

## What Changes

- per-card 间隔选择：点「确定」后 **不立即关闭** Sheet；标题改为「大概 {间隔} 一次」（可保留事件 logo）；隐藏滚轮；逐字展示智能分析思考文案（节奏/叙事对齐量身定做思考打字机）。
- 思考文末 **另起一行加粗**：说明随着后续喂养节奏会自动修改预测时间，当前仅为适应喂养信息不足时的临时推演。
- 底部按钮（策略 **A**）：思考播放中为「跳过动画」；全文展示后变为「关闭」，点按关闭 Sheet。
- 种子写入时机：与量身定做一致——切入思考态 **之前** upsert `PredictionRecallSeed`（确认即生效）；关闭仅 dismiss。
- **不得** 把思考态塞进通用 `showGlassSingleWheelPickerSheet`（避免污染其它滚轮）；专用 recall 间隔 Sheet body。
- 本 change **不**删除量身定做 Dialog 残留源码。

## Capabilities

### New Capabilities

- `prediction-interval-sheet-thinking`：per-card 间隔 Sheet 确认后同层思考打字机与关闭门闸。

### Modified Capabilities

- `prediction-recall-per-card-interval`：确认路径从「选完即关」改为「选完 → 思考 → 关闭」；种子仍在确认时写入。

## Impact

- **Flutter**：`prediction_recall_interval_picker.dart`（或专用 Sheet）、可选抽出打字机小工具供 onboarding 与 per-card 共用；`smart_prediction_screen` 的 `_onPickIntervalRecall` 与 Sheet 回调衔接。
- **API / Android**：无。
- **测试**：不新建 `**/test/**`；手工验收确认→思考→关闭、跳过动画、种子与 countdown 生效。
