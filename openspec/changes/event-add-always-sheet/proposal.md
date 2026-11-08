## Why

普通新增对 `time`/`one` 仍常「一点即落库」（喂养页、目录多级 picker 后、预测深入后），与已统一的 `number` sheet 心智不一致，也容易误触。产品要求：`time`/`one` 与 `number` 一样先开统一记录 sheet；预测页不得再弹「确认添加」。

## What Changes

- `EventRecordIntent.add`：`time` / `one` / `number` **一律**打开统一记录 sheet 后再提交；**不得**即时 now / 即时开计时落库。
- 入口覆盖：喂养事件格、目录多级选叶后、预测卡直点与深入后（凡经 `handleEventGridTap` / `_onEventButtonTap`）。
- 预测页：**不得**再以「确认添加」玻璃确认框作为闸；直接 sheet。
- `time` 已在计时中：保留现有 toast，不打开重复计时 sheet。
- `supplement`：仍直接 sheet（现状），不回归确认框。
- 可删除/闲置仅服务于「预测直点才 sheet」的 `preferRecordSheet` / `confirmDirectLeafBeforeAdd` 特殊分支（实现可简化）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `event-record-sheet`：全局 `add` 对 `time`/`one` 必须走统一 sheet；废止预测确认框路径。
- `history-event-add`：若基线假定喂养格 `time`/`one` 即时提交，改为 sheet 后再 add。

## Impact

- 主要：`app/lib/ui/event_add_actions.dart`；预测/喂养调用方可简化 flag。
- 用户可见：喂养点 time 不再一点开计时，需在 sheet 确认。
- 无服务端 / **BREAKING** API 变更。
