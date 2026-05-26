## Context

- **现状**：`showHomeNumberEventSheet` 经 `showAppAdaptiveBottomSheet` 展示 `_HomeNumberEventSheet`，内容为普通 `Padding` + `OutlinedButton` + 默认 `TextField` + `FilledButton`。
- **参照**：`home_history_edit_sheet.dart` + `HistoryEditGlassPanel`；`home_event_hourly_trend_sheet.dart` 透明 modal 模式。
- **约束**：保留 `EventNumberMemoryStore`、`initialUsage`、`HomeNumberEventResult` 契约；不新增测试文件（仓库规则）。

## Goals / Non-Goals

**Goals:**

- 新增用量 Sheet 与历史编辑/趋势 Sheet 玻璃视觉一致（磨砂面板、事件色渐变、浅色前景、× 关闭）。
- 日期/时间、备注、滚轮、确认 CTA 在玻璃区内可读、可点。
- 弹层使用透明背景 + 半透明 barrier（与编辑 Sheet 一致）。

**Non-Goals:**

- 不改 number 事件聚合、记忆键、API 提交字段。
- 不重构 `HomeEventNumberPicker` 档位算法。
- 不统一改造所有 `showAppAdaptiveBottomSheet` 调用方。

## Decisions

1. **弹层入口**  
   - **选择**：`showModalBottomSheet` + `backgroundColor: Colors.transparent` + `isScrollControlled: true`，内层 `HistoryEditGlassPanel`（与趋势 Sheet 同模式）。  
   - **备选**：给 `showAppAdaptiveBottomSheet` 加 `glass: true` — 仅一处调用，直接专用入口更简单。

2. **组件复用**  
   - **选择**：复用 `HistoryEditGlassPanel`、`historyEditGlassInputDecoration`、`historyEditGlassTextColor`、`EventLogo`、`resolveEventColor`。  
   - 日期/时间：优先 `HistoryEditGlassTapField` 或两行玻璃 tap 条展示 `formatHistoryApiDateTime` 片段，点击仍调 `showDatePicker` / `showTimePicker`。

3. **滚轮样式**  
   - **选择**：在玻璃子树包 `CupertinoTheme`（`textTheme` 浅色）或 picker 子项 `Text` 使用 `glassTextColor`。  
   - 不改为 Material 滚轮，保持与编辑 Sheet 一致。

4. **确认按钮**  
   - **选择**：面板底部 `FilledButton`（accent 填充、圆角 12+），文案「确认记录」；关闭仅 ×，避免双 CTA 混乱。  
   - **备选**：取消+保存双按钮 — 新增场景仅需确认，× 即取消。

5. **布局**  
   - `Column(mainAxisSize: min)`：Logo/标题 → 日期时间行 → 滚轮 → 备注 → 确认。  
   - 最大高度：沿用约 2/3 屏或内容 intrinsic，内层可 `SingleChildScrollView` 防小屏溢出。

## Risks / Trade-offs

- **[Risk] 浅色 shell 下玻璃固定浅色字对比不足** → 与编辑 Sheet 相同策略：玻璃区固定 `glassTextColor`，不跟 `onShell` 变暗。  
- **[Risk] CupertinoPicker 在深色渐变上默认灰字** → 显式 CupertinoTheme / TextStyle。  
- **[Risk] 透明 sheet 与 `AppAdaptiveBottomSheet` 行为分叉** → 仅改 `home_number_event_sheet.dart` 入口，文档注明。

## Migration Plan

- 单 PR 替换 UI；无数据迁移。  
- 回滚：恢复 `showAppAdaptiveBottomSheet` 与原 build 方法即可。

## Open Questions

- 日期/时间是否合并为单条「时刻」玻璃 field（与编辑 Sheet 双字段对齐）— 实现时优先 **一行两格** 玻璃按钮，与现逻辑等价。
