# Proposal: 喂养事件备注快捷标签

## Why

Web 或长时间挂机后 token 过期需重新登录，用户在备注输入框中已输入的内容会丢失；即使重登后，常用备注（如「左侧」「溢奶」）也需反复手打，记录效率低。

## What Changes

- 按 **eventId** 在本地缓存每个事件最近 **3** 条非空备注（LRU、去重）。
- 在 **number 事件二级页** 与 **历史编辑 Sheet** 的备注输入框下方展示快捷标签。
- 点击标签 **替换** 输入框全文；长备注 **不截断**；标签 **Wrap** 布局，间距 3px，主题色边框/文字、0.3 透明填充。
- 不同 eventId 的缓存 **互不影响**；不按宝宝/deviceNo 隔离。
- **不**改动 token 刷新、输入草稿持久化或 time/one 创建流程。

## Capabilities

### New Capabilities

- `event-remark-quick-tags`：本地备注缓存与快捷标签 UI 行为。

### Modified Capabilities

- `home-number-event-glass-sheet`：number 二级页增加备注快捷标签展示与确认后写入缓存。
- `home-history-edit-sheet`：历史编辑页增加备注快捷标签展示与保存成功后写入缓存。

## Impact

- 新增 `EventRemarkMemoryStore`（SharedPreferences，mirror `EventNumberMemoryStore`）。
- 新增 `EventRemarkQuickTags` 组件。
- 修改 `home_number_event_sheet.dart`、`home_history_edit_sheet.dart`。
