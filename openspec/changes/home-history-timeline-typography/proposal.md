# Proposal: 主页历史时间轴排版与 eventUnit

## Why

主页历史行当前事件名、数量尾注与计时文案视觉层级不足；计数类事件缺少单位展示（如 120ml）。需在服务端持久化事件单位并在历史写入时反规范化，同时升级客户端时间轴排版以突出关键数字。

## What Changes

- 主页历史行：事件名 **1.5×**；备注保持原字号；尾注数字 **2× 加粗 + 事件强调色**，单位后缀正常字号。
- 计数事件尾注：去掉 `→`，展示 **数量 + eventUnit**（无单位则仅数字）。
- 进行中/已结束计时：elapsed/duration 中数字采用与计数相同的强调样式。
- 行高由 37px 略增至约 40px。
- 后端 `go_ai_talk`：`event.unit`、`history.event_unit` 列；管理端单位字段；历史写入时反规范化 unit；DeepSeek 新建 number 事件时生成 unit；list/WS 返回 `eventUnit`。
- Flutter 客户端 add/update 请求体**仍不得**发送 `eventUnit`（沿用既有契约）。

## Capabilities

### New Capabilities

- `history-event-unit`: 事件主档 unit 与历史行 event_unit 反规范化及 API/WS 返回。

### Modified Capabilities

- `home-history-timeline-row`: 时间轴行排版、尾注数量+单位、计时数字强调、行高。
- `home-history-compact-timeline`: 行高常量与 `HomeHistoryTimelineTile` 视觉层级对齐。

## Impact

- **Flutter**: `history_line_format.dart`, `home_history_timeline_tile.dart`, `event_definition.dart`, `home_history_scroll.dart`（行高引用）。
- **go_ai_talk**: entity/dao、`history_row.go`, `device_history.go`, `realtime_notify.go`, `admin.go`, `device_admin_event.go`, `admin.html`, `voice_chat_understanding.go`, `event_child_pending.go`；需执行 DDL 迁移。
