## 1. 共享玻璃 Overlay 基础设施

- [x] 1.1 新增 `app/lib/ui/widgets/app_glass_overlay.dart`，实现 `showGlassAdaptiveBottomSheet`（透明 sheet、统一 `barrierColor`、默认 `HistoryEditGlassPanel` 包裹、`maxHeightFraction` / `enableDrag` / `onClose` / `eventAccent` 参数）
- [x] 1.2 在同文件实现 `showGlassDialog`（居中、`maxWidth`、可选 `maxHeightFraction`、`barrierDismissible`、默认玻璃面板）
- [x] 1.3 玻璃 Sheet 内部复用 `AppAdaptiveBottomSheet` 的高度与 `viewInsets` 处理；为 catalog 等自带 `ListView` 的场景提供 `scrollable` 或等价参数避免双滚动

## 2. 优先迁移：目录与子事件选择器

- [x] 2.1 `event_catalog_picker_sheet.dart`：改用 `showGlassAdaptiveBottomSheet`，移除 `themePrimaryBlend` 实心底；列表/面包屑/返回使用 `historyEditGlassTextColor` / `historyEditGlassLabelColor`
- [x] 2.2 手工验证：文件夹下钻、返回上一级、选叶子 pop、不可记录叶子 toast 行为不变

## 3. 迁移尚未玻璃化的 Bottom Sheet

- [x] 3.1 `home_reply_bottom_sheet.dart`：改用玻璃入口，长回复可滚动，标题与正文使用玻璃前景色
- [x] 3.2 `home_history_time_wheel.dart` 中 `showHomeHistoryTimePickerSheet`：改用玻璃入口，滚轮区保持现有交互
- [x] 3.3 `trends_screen.dart` 内联事件 `showModalBottomSheet`：提取或内联改为玻璃入口，列表项视觉与主页目录 picker 对齐

## 4. 已玻璃 Sheet 去重（统一入口）

- [x] 4.1 `home_history_edit_sheet.dart`：`showHomeHistoryEditSheet` 改用 `showGlassAdaptiveBottomSheet`，删除重复 transparent/bottomPad 样板
- [x] 4.2 `home_number_event_sheet.dart`：同上，`enableDrag: false` 等行为通过参数保留
- [x] 4.3 `home_event_hourly_trend_sheet.dart`：改用玻璃入口，保留横屏 `maxHeightFraction` 覆盖
- [x] 4.4 `trends_date_range_glass_sheet.dart`：改用玻璃入口，保留现有表单与滚轮

## 5. 迁移 Dialog / AlertDialog

- [x] 5.1 `home_active_timing_reminder_dialog.dart`：改用 `showGlassDialog`，行为与布局不变
- [x] 5.2 `home_history_edit_sheet.dart` 内嵌删除/停止等 `AlertDialog`：改为 `showGlassDialog`
- [x] 5.3 `home_screen.dart` 两处确认 `AlertDialog`：改为 `showGlassDialog`
- [x] 5.4 `settings_screen.dart` 全部 `AlertDialog`（含颜色选择）：改为 `showGlassDialog`
- [x] 5.5 `version_prompt.dart` 版本提示与 APK 下载进度：改为 `showGlassDialog`

## 6. 收尾与验证

- [x] 6.1 全库检索 `showModalBottomSheet` / `showDialog` / `AlertDialog`，确认弹层均已迁移或注明非玻璃例外（不应有遗漏的业务弹层）
- [x] 6.2 运行 `flutter analyze`（`app` 包）并本地走查：目录 picker、历史编辑、number 添加、回复展开、趋势页 picker、设置确认、版本提示、计时提醒
- [x] 6.3 不新增 `test/` 下文件（遵守仓库规则）
