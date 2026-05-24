## Why

历史详情页当前加载后直接展示可编辑表单（备注、时间选择器、底部「保存」），用户无法先完整查看该条记录再决定是否修改。需改为**默认只读预览**，通过 AppBar「编辑」进入编辑态；编辑态仍用底部「保存」，且预览与编辑页均**不展示**「创建时间」字段。

## What Changes

- 详情页增加 `view` / `edit` 两种模式；进入后默认为 **view**。
- **预览模式**：结构化只读展示（事件名、按 `eventNumber` 的起止/结束/用量/用时、备注等）；AppBar 提供「编辑」「删除」；不显示 `createdAt` 创建时间。
- **编辑模式**：保留现有可编辑字段与校验；AppBar 提供「取消」回到预览；底部 **「保存」** 按钮；同样不显示创建时间。
- 取消编辑时从 `_record` 重置表单，丢弃未保存改动；保存/删除成功行为与现网一致（`pop(true)` 等）。
- 不改变 `updateHistoryRecord` / `deleteHistoryRecord` 请求语义。

## Capabilities

### New Capabilities

- `history-detail-view-mode`：详情默认预览、显式进入编辑、取消与返回拦截规则。

### Modified Capabilities

- `history-detail-screen`：补充默认非编辑展示；明确不得展示创建时间；编辑入口与保存位置。

## Impact

- `app/lib/ui/history_detail_screen.dart`（主改动）
- 可选：从 `history_line_format` / `history_mapper` 复用只读文案，无 API 变更
- OpenSpec delta：`history-detail-editable-fields` 对应 spec 合并归档
