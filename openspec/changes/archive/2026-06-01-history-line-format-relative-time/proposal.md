## Why

首页与历史相关列表当前以「事件名:动作」的固定拼接展示，无法区分单次记录、多次计数、进行中与已结束的计时语义，也无法按「今天 / 昨天 / 今年 / 其它」做贴近阅读的相对时间呈现。需要按业务约定的 `eventNumber`、`startTime`、`endTime`、`remark` 规则统一主文案，并在 UI 上对事件名与备注区分字重与字号。

## What Changes

- 按 `eventNumber` 与 `endTime`（缺失视为 0）分支，生成一条历史记录的主展示文案（含相对时间格式与用时展示规则）。
- 相对时间：`今日` 仅展示时分；`昨日` 展示「昨天 + 时分」；`今年` 内非今昨展示「月日 + 时分」；其它展示「年月日 + 时分」。
- 计时类：`eventNumber = 0` 且 `endTime = 0` 展示开始计时文案；`eventNumber = 0` 且 `endTime > 0` 展示为「`{格式化(endTime)}:{eventName}-> 用时{时长}`」。
- 视觉：`eventName` 字重加粗、字号加大；`remark` 字号缩小（相对同条内事件名）。
- 若需从 `HistoryRecord` 或 `rawPayload` 读取新字段以完成上述规则，在映射层补齐并保持与网关字段（camelCase）一致。

## Capabilities

### New Capabilities

- `history-line-display`：历史列表单行文案拼接规则、相对时间格式化规则，以及首页列表中事件名与备注的排版语义（字重/字号层级）。

### Modified Capabilities

- （无根目录 `openspec/specs` 基线；本次以新增能力规格为主。）

## Impact

- Flutter：`HistoryRecord` 展示路径（如 `displayLine`、首页 `ListView` 的 `Text`、历史详情若有同类展示）、`history_mapper.dart` 与可能的 `models.dart` 辅助方法。
- 与既有 WebSocket / HTTP 列表字段 `eventNumber`、`startTime`、`endTime`、`eventName`、`remark` 的解析与缺省约定（字段缺失与 `0` 的等价语义需在实现与规格中一致）。
