## Context

- `HistoryDetailScreen` 在 `_load` 后 `build` 中直接渲染 `Form` + `_editFields` + 底部 `FilledButton(保存)`。
- 页头已有只读「事件名」与一行 `historyLineSpans`，但与表单混排，整体观感为「进来就编辑」。
- 既有变更 `history-detail-editable-fields` 规定按 `eventNumber` 可编字段；本变更只改**模式与展示**，不改网关。

## Goals / Non-Goals

**Goals:**

- 默认 **view**：只读描述列表（label / value），字段完整可读。
- AppBar **编辑**（`Icons.edit_outlined`）→ **edit**；**取消** 回 view 并重置 controllers。
- **edit**：现有 `_editFields` + 底部 **保存**；删除在 view/edit 均可（或两态均保留删除图标）。
- **预览与编辑均不展示** `record.createdAt` 或「创建时间」文案（移除现有 `创建时间：…` 行）。
- 编辑中有未保存改动时，系统返回键 / AppBar 返回需确认（`PopScope`）。

**Non-Goals:**

- 不改路由、不改 `getRecord` / 更新删除 API。
- 不在预览页提供内联编辑。
- 不新增「创建时间」相关展示。

## Decisions

### 1. 模式状态

```dart
enum _HistoryDetailMode { view, edit }
var _mode = _HistoryDetailMode.view;
```

- `_enterEdit()`：`setState(() => _mode = edit)`，controllers 已由 `_load` 填充。
- `_cancelEdit()`：从 `_record` 调用与 `_load` 相同的灌入逻辑，`_mode = view`。
- `_save()` 成功：`context.pop(true)`（与现网一致）。

### 2. AppBar

| 模式 | leading | title | actions |
|------|---------|-------|-----------|
| view | back → `pop(false)` | 事件名（空则「历史详情」） | 编辑、删除 |
| edit | back → 若脏则确认 else `_cancelEdit` | 「编辑」或事件名 | 取消（`TextButton`）、删除 |

### 3. 预览 body（`_buildPreview`）

按 `eventNumber` 与 `_editFields` 对称，只读 `ListTile` 或 `Row`+label：

| n | 展示项 |
|---|--------|
| 0 | 事件名、开始时间、结束时间（未设置→「未结束」）、用时（已结束时 `formatDurationForEvent0`）、备注 |
| 1 | 事件名、结束时间、备注 |
| >1 | 事件名、结束时间、用量+`eventUnit`、备注 |

时间值用 `formatHistoryApiDateTime`；**不展示** `createdAt`。

可选：保留一行 `historyLinePlainText` 作摘要——若与分项重复可省略，首版以分项为准。

### 4. 编辑 body

- 移除 `创建时间` Text（约 297–300 行）。
- `Form` + `_editFields` + 底部 `FilledButton(保存)` 仅在 `_mode == edit` 时渲染。
- 事件名仍只读置于表单上方（view/edit 均可显示一次）。

### 5. 未保存拦截

- `_formDirty`：对比 controllers / `_startEdit` / `_endEdit` 与 `_record` 灌入初值。
- `PopScope(canPop: false, onPopInvokedWithResult: …)` 在 edit 且 dirty 时弹窗「放弃修改？」。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 预览与编辑字段不一致 | 预览字段表与 `_editFields` 分支同一 `n` 来源 |
| 取消未重置 `_endEdit` | `_cancelEdit` 复用 `_load` 灌入片段 |
| 删除在编辑态误触 | 保持确认对话框 |

## Migration Plan

- 单屏 UI 变更；发版即生效。

## Open Questions

- 无（用户已确认：底部保存、不展示创建时间）。
