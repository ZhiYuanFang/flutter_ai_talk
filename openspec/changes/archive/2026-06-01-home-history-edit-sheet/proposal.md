## Why

主页点击历史记录当前会跳转全屏二级页（预览 → 编辑），打断用户在主页的上下文；时间选择使用 Material 对话框且可改日期，与「仅调整当日时分」的业务习惯不一致。将编辑/删除/停止计时收敛到主页底部 Sheet，可缩短操作路径，并与添加事件时已有的 Bottom Sheet + Cupertino 滚轮交互保持一致。

## What Changes

- **主页内联编辑**：点击历史行不再 `push` `/history/:id`，改为在主页底部弹出编辑 Sheet（`showModalBottomSheet`），直接展示可编辑字段（无独立预览模式）。
- **滚轮时分**：开始/结束时间使用 **Cupertino 滚轮** 选择 **时、分**；**日期锁定**为记录原有日期，**不得**在 Sheet 内修改日期。
- **按 eventNumber 字段**：沿用现有规则——`0` 可编辑开始/结束（结束可清空）；`1` 仅结束；`>1` 结束 + 用量滚轮（与 `home_number_event_sheet` 添加流程一致的 5–500 步进档位）。
- **计时停止**：`eventNumber == 0` 且计时中时，Sheet 内 **必须** 提供「停止」操作（写入结束时间并关闭/刷新行），与列表行停止语义一致。
- **pending 只读**：`pending:*` 乐观记录打开 Sheet 时为 **只读**（展示字段，禁用保存/删除/停止/滚轮修改），避免与 HTTP 对账竞态。
- **删除**：Sheet 内提供删除当前事件（二次确认 → `POST delete` → 本地列表移除）。
- **移除二级页**：删除 `HistoryDetailScreen` 及 `/history/:recordId` 路由；移除预览/编辑全屏相关代码。
- **Bottom Sheet 布局统一**：**所有**从底部弹出的 Sheet **最大高度为屏幕 2/3**；内容不足 2/3 时 **自适应内容高度**，**不得** 固定占满 2/3（含事件目录 picker、number 添加、回复展示、新建历史编辑 Sheet）。
- **BREAKING**：深链 `/history/:recordId` 不再可用；外部文档/README 中「历史详情页」描述需更新。

## Capabilities

### New Capabilities

- `home-history-edit-sheet`：主页历史记录 Bottom Sheet 编辑/删除/计时停止、滚轮时分、pending 只读、与网关 update/delete 及本地 `homeHistoryProvider` 同步。
- `app-bottom-sheet-layout`：全 App 底部弹框最大 2/3 屏高、内容不足时 intrinsic 高度、溢出内滚动的共享布局约束。

### Modified Capabilities

- `history-detail-screen`（变更 `history-detail-editable-fields` / `history-detail-view-mode`）：**废止**全屏历史详情页与预览模式；同等编辑/删除/停止语义迁移至 `home-history-edit-sheet`。

## Impact

- **删除**：`app/lib/ui/history_detail_screen.dart`；`app_router.dart` 中 `/history/:recordId`。
- **新增**：`home_history_edit_sheet.dart`（或等价命名）、共享 `app_adaptive_bottom_sheet.dart`（或等价布局组件）。
- **修改**：`home_screen._openHistory` → 弹出 Sheet；`event_catalog_picker_sheet`、`home_number_event_sheet`、`home_reply_bottom_sheet` 套用统一高度规则。
- **复用**：`history_mapper` 的 update body、`FeedRepository.updateHistoryRecord` / `deleteHistoryRecord`、用量滚轮常量与 `home_number_event_sheet`。
- **文档**：`app/README.md` 主页历史交互描述。
