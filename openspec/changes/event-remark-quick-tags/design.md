# Design: 喂养事件备注快捷标签

## 概述

按 `eventId` 在 SharedPreferences 中缓存最近 3 条非空备注，在 number 二级页与历史编辑 Sheet 的备注输入框下方以 Wrap 标签展示；点击标签替换输入框全文。

## 数据层

- 新类 `EventRemarkMemoryStore`（`app/lib/config/event_remark_memory_store.dart`），模式 mirror `EventNumberMemoryStore`。
- Key：`event_remark_recent_v1_{eventId}`；Value：JSON 字符串数组，最多 3 条，LRU + 去重。
- `load(eventId)` → `List<String>`；`save(eventId, remark)` 在 remark 非空时写入。
- **不**按 deviceNo 隔离；eventId 为空时不读写。

## UI 组件

- 新 widget `EventRemarkQuickTags`（`app/lib/ui/widgets/event_remark_quick_tags.dart`）。
- 入参：`eventId`、`onSelect(String)`。
- `initState` async load；0 条时不占位。
- `Wrap(spacing: 3, runSpacing: 3)`；每个标签：
  - 边框 + 文字：`Theme.of(context).colorScheme.primary`
  - 填充：`primary.withValues(alpha: 0.3)`
  - 圆角 `BorderRadius.circular(8)`；内边距 `horizontal: 10, vertical: 6`
  - 长文本不截断，自然换行（标签内 `Text` 不设 maxLines）
- 点击：`onSelect(remark)`；父组件设置 controller 并调用 `keyboardInputBridgeController.updateDraft`。

## 接入点

| 文件 | eventId 来源 | 写入时机 |
|------|-------------|---------|
| `home_number_event_sheet.dart` | `widget.event.id` | `_confirm()` 弹出结果前 |
| `home_history_edit_sheet.dart` | `historyRecordEventId(r)` | `_save()` 成功后、`Navigator.pop` 前 |

## 不在范围

- token 刷新、备注草稿持久化
- time/one 创建流程 remark UI
- 标签删除/编辑、按宝宝隔离
