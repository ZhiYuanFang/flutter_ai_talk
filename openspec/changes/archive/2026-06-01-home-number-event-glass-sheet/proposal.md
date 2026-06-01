## Why

主页 **number / 用量类事件**（如奶量）的新增二级 Sheet 仍使用默认 Material 底栏（系统 surface、Outlined 按钮与输入框），与已落地的历史编辑玻璃 Sheet、今日趋势玻璃 Sheet 视觉不一致，层级弱、品牌感不统一。需在**不改变用量选择、时刻选择与提交逻辑**的前提下，将新增弹窗对齐玻璃拟态规范。

## What Changes

- **弹层容器**：由 `showAppAdaptiveBottomSheet` 默认样式改为透明 modal + 内层 `HistoryEditGlassPanel`（磨砂、渐变、圆角、事件色 tint、右上关闭）。
- **头部**：居中 **事件 Logo** + **事件名**（玻璃浅色前景），替代纯文本 `titleMedium`。
- **时刻选择**：日期/时间改为玻璃质感可点击条（或统一玻璃 Outlined 风格），文字使用 `historyEditGlassTextColor` / 标签色。
- **用量滚轮**：沿用 `HomeEventNumberPicker`；滚轮与选中项文字适配深色玻璃底（CupertinoTheme / 固定浅色）。
- **备注**：使用 `historyEditGlassInputDecoration` 玻璃输入框。
- **主操作**：底部 **确认记录** 为玻璃区内实心 pill（事件 accent 或统一 CTA），取消/关闭通过 × 或返回 dismiss。
- **行为保持**：`EventNumberMemoryStore` 记忆、`initialUsage`、确认后 `HomeNumberEventResult` 字段与 `home_screen` 提交流程不变。
- **非目标**：历史编辑 Sheet、趋势 Sheet 重做；number 事件业务规则与 API 不变。

## Capabilities

### New Capabilities

- `home-number-event-glass-sheet`：number 类型事件新增 Sheet 的玻璃拟态视觉与交互呈现规范。

### Modified Capabilities

- （无）仓库根目录 `openspec/specs/` 暂无基线能力；不修改其他变更内 delta。

## Impact

- `app/lib/ui/home_number_event_sheet.dart` — 布局与样式重构；弹层入口改为透明 `showModalBottomSheet` 或扩展 `showAppAdaptiveBottomSheet` 参数
- 复用：`home_history_edit_glass_panel.dart`、`event_logo.dart`、`home_event_number_picker.dart`
- 可选：`app/lib/ui/widgets/app_adaptive_bottom_sheet.dart` — 仅当需共享透明玻璃外壳参数
- 无后端 / API 变更
