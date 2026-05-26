## Why

子事件目录选择器（`event_catalog_picker_sheet`）仍使用主题色实心 Bottom Sheet，与主页历史编辑、数值事件、趋势日期范围等已落地的玻璃拟态弹层不一致，品牌感割裂。同时项目内仍有若干 `showModalBottomSheet` / `showDialog` / `AlertDialog` 入口各自重复透明背景、遮罩、内边距与高度约束，后续新增弹层易再次偏离统一视觉。需要在**不改变业务交互语义**的前提下，统一全部底部 Sheet 与居中对话框的玻璃风格，并抽出可复用的展示入口供后续功能直接调用。

## What Changes

- **统一玻璃 Bottom Sheet 入口**：在现有 `showAppAdaptiveBottomSheet` / `HistoryEditGlassPanel` 基础上新增共享 helper（如 `showGlassAdaptiveBottomSheet`），约定透明 sheet 背景、半透明遮罩、最大高度、安全区与键盘 inset，内层默认包裹玻璃面板（可传 `eventAccent`）。
- **子事件目录选择器玻璃化**：`event_catalog_picker_sheet.dart` 迁移至共享入口，列表/面包屑使用固定浅色前景，与历史编辑 Sheet 一致。
- **补齐未玻璃化的 Sheet**：迁移 `home_reply_bottom_sheet`、`home_history_time_wheel` 时分选择、`trends_screen` 内联事件选择器等仍使用 Material 默认 surface 的底部弹层。
- **统一居中对话框**：为 `showDialog` + `HistoryEditGlassPanel` 模式抽取 `showGlassDialog`（或等价 API），将设置页、版本提示、主页确认框、历史编辑内嵌 `AlertDialog` 等迁移为玻璃居中模态（计时提醒对话框已部分对齐，改为走共享入口）。
- **非目标**：不改动 Sheet/Dialog 内业务字段校验、API、路由；不新增自动化测试文件；不调整图表页内嵌玻璃柱图等非弹层 UI。

## Capabilities

### New Capabilities

- `app-glass-overlay`：应用级玻璃拟态 Bottom Sheet 与居中 Dialog 的统一展示入口、视觉 token 约定及迁移后的行为要求。

### Modified Capabilities

- `app-bottom-sheet-layout`（变更 `home-history-edit-sheet` 归档能力）：补充「应优先通过玻璃 overlay helper 展示」及透明背景 + 内层玻璃面板的规范，与既有 2/3 屏高规则并存。
- `home-button-event-tree-nav`（变更 `event-catalog-parent-tree`）：目录选择 Sheet 必须采用玻璃拟态容器，而非主题色实心底栏。

## Impact

- **新增**：`app/lib/ui/widgets/` 下玻璃 overlay helper（具体文件名见 design.md）
- **迁移 Sheet**：`event_catalog_picker_sheet.dart`、`home_reply_bottom_sheet.dart`、`home_history_time_wheel.dart`、`trends_screen.dart`（内联 picker）、`widgets/app_adaptive_bottom_sheet.dart`（扩展或委托）
- **已玻璃、改入口**：`home_history_edit_sheet.dart`、`home_number_event_sheet.dart`、`home_event_hourly_trend_sheet.dart`、`trends_date_range_glass_sheet.dart`
- **迁移 Dialog**：`home_active_timing_reminder_dialog.dart`、`home_history_edit_sheet.dart`（内嵌确认）、`home_screen.dart`、`settings_screen.dart`、`version_prompt.dart`
- **复用组件**：`home_history_edit_glass_panel.dart`（`HistoryEditGlassPanel` 及文字/输入装饰 helper）
- 无后端/API 变更
