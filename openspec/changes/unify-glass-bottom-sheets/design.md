## Context

项目已具备成熟的玻璃拟态实现：`HistoryEditGlassPanel`（`BackdropFilter` blur σ=20、圆角 22、渐变填充、微光描边、固定浅色前景）及 `historyEditGlassTextColor` / `historyEditGlassLabelColor` 等 helper。以下 Sheet **内容区**已玻璃化，但入口各自手写 `showModalBottomSheet` 参数：

| 文件 | 入口 | 玻璃状态 |
|------|------|----------|
| `home_history_edit_sheet.dart` | `showModalBottomSheet` transparent | 内容 ✓，入口未统一 |
| `home_number_event_sheet.dart` | 同上 | 内容 ✓ |
| `home_event_hourly_trend_sheet.dart` | 同上 | 内容 ✓ |
| `trends_date_range_glass_sheet.dart` | 同上 | 内容 ✓ |
| `home_active_timing_reminder_dialog.dart` | `showDialog` + 居中 `HistoryEditGlassPanel` | 内容 ✓ |

以下仍使用 **Material 实心底栏** 或 **AlertDialog**，需迁移：

| 文件 | 入口 | 问题 |
|------|------|------|
| `event_catalog_picker_sheet.dart` | `showAppAdaptiveBottomSheet` + `themePrimaryBlend` | 非玻璃 |
| `home_reply_bottom_sheet.dart` | `showAppAdaptiveBottomSheet` 默认 | 非玻璃 |
| `home_history_time_wheel.dart` | `showAppAdaptiveBottomSheet`（时分选择） | 非玻璃 |
| `trends_screen.dart` | 内联 `showModalBottomSheet` + `colorScheme.surface` | 非玻璃 |
| `home_history_edit_sheet.dart` | 内嵌 `AlertDialog`（删除/停止确认） | 非玻璃 |
| `home_screen.dart` | `AlertDialog` ×2 | 非玻璃 |
| `settings_screen.dart` | `AlertDialog` ×4 | 非玻璃 |
| `version_prompt.dart` | `AlertDialog` + 下载进度 | 非玻璃 |

现有 `showAppAdaptiveBottomSheet`（`app_adaptive_bottom_sheet.dart`）负责 2/3 屏高与滚动，默认 Material 背景与 drag handle，与玻璃透明外层模式并存但不重叠。

## Goals / Non-Goals

**Goals:**

- 新增 **`app_glass_overlay.dart`**（或 `app/lib/ui/widgets/` 下等价命名），作为所有玻璃 Sheet/Dialog 的**唯一推荐入口**。
- `showGlassAdaptiveBottomSheet<T>`：透明 sheet、`barrierColor` 统一、复用 `AppAdaptiveBottomSheet` 高度约束，默认用 `HistoryEditGlassPanel` 包裹 `bodyBuilder` 内容。
- `showGlassDialog<T>`：居中、`barrierDismissible`、最大宽度/高度约束，默认 `HistoryEditGlassPanel`；支持 `title` / `actions` 或纯 `contentBuilder`。
- 将上表全部调用点迁移至共享入口；`event_catalog_picker_sheet` 作为用户明确诉求优先验收。
- 保留 `HistoryEditGlassPanel` 为视觉单一来源；blur/圆角/前景色不复制第二套。

**Non-Goals:**

- 不修改 `HistoryEditGlassPanel` 的渐变算法（除非修 bug）。
- 不玻璃化非弹层 UI（如 `trend_glass_bar_chart` 内嵌图表、toast）。
- 不新增 `test/` 下文件。
- 不改变各 Sheet 的业务返回值类型与 Navigator pop 语义。

## Decisions

### 1. 新文件 `app_glass_overlay.dart` 而非仅扩展 `app_adaptive_bottom_sheet.dart`

**选择**：独立 overlay 模块，`app_adaptive_bottom_sheet.dart` 继续服务**非玻璃**或内部布局；玻璃入口内部调用 `showModalBottomSheet` + `AppAdaptiveBottomSheet`。

**理由**：避免 `showAppAdaptiveBottomSheet` 默认参数与玻璃透明模式互相污染；历史变更 `app-bottom-sheet-layout` 明确「非历史编辑 Sheet 可保留默认 Material」——玻璃为 opt-in 上层。

**备选**：在 `showAppAdaptiveBottomSheet` 增加 `useGlass: true` —— 参数组合爆炸，否决。

### 2. API 签名（提议）

```dart
/// 玻璃拟态底部 Sheet：透明外层 + 可选事件色 accent + 内层 HistoryEditGlassPanel。
Future<T?> showGlassAdaptiveBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder bodyBuilder,
  Color? eventAccent,
  VoidCallback? onClose,
  EdgeInsets? glassContentPadding,
  double maxHeightFraction = 2 / 3,
  bool showDragHandle = false,
  bool enableDrag = true,
  bool isDismissible = true,
  bool wrapInGlassPanel = true,
});

/// 居中玻璃对话框。
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder contentBuilder,
  Color? eventAccent,
  VoidCallback? onClose,
  double maxWidth = 340,
  double? maxHeightFraction,
  bool barrierDismissible = true,
});
```

- `bodyBuilder` / `contentBuilder` 收到的是**玻璃面板内部**的 `BuildContext`（已包 padding），与现 `HistoryEditGlassPanel.child` 一致。
- `eventAccent` 传入 `HistoryEditGlassPanel.eventAccent`，用于底部渐变染色（目录 picker 可用根事件色或 `themePrimaryBlend` 派生）。
- `maxHeightFraction`：趋势小时 Sheet 等可传 `0.58` / `0.92`（横屏）覆盖默认 2/3，由调用方显式指定，避免 helper 隐式特殊 case。

### 3. 视觉 token 来源

继续使用 `HistoryEditGlassPanel` 内常量（`_blurSigma = 20`、`_radius = 22`）及 `AppVisualTokens.isDarkShell` 决定填充 alpha，**不在 overlay 重复定义 blur**。若未来需全局调节，再抽 `GlassOverlayTokens` theme extension（本变更不引入，降低范围）。

### 4. AlertDialog 迁移策略

将 `AlertDialog` 的 `title` / `content` / `actions` 重组为 `showGlassDialog` 的 `Column`：主按钮用实心 pill（与历史编辑保存钮一致），取消用 `TextButton` + `historyEditGlassLabelColor`。下载进度等特殊内容保留 `contentBuilder` 自定义，外层仍走 `showGlassDialog`。

### 5. 已玻璃 Sheet 的 refactor

`home_history_edit_sheet`、`home_number_event_sheet` 等仅替换 `showModalBottomSheet` 块为 `showGlassAdaptiveBottomSheet`，删除重复的 `Padding` / `ConstrainedBox` / `barrierColor` 样板代码；**不改变** `enableDrag: false` 等行为（通过 helper 参数传递）。

### 6. `showAppAdaptiveBottomSheet` 保留

非玻璃场景（若仍有）或玻璃 helper 内部布局层继续使用；`showHomeReplyBottomSheet` 等迁移后不再直接调用裸 `showAppAdaptiveBottomSheet`。

## Risks / Trade-offs

- **[Risk] 双层滚动**：`AppAdaptiveBottomSheet` 内 `SingleChildScrollView` + 玻璃面板内再滚动 → **Mitigation**：玻璃 sheet 的 `bodyBuilder` 对已是 `ListView` 的页（catalog picker）使用 `primary: false` 或 helper 增加 `scrollable: false` 可选参数。
- **[Risk] 性能**：全站 Dialog 均 `BackdropFilter` → **Mitigation**：沿用现有 `RepaintBoundary`；设置页等低频对话框可接受。
- **[Risk] 浅色主题可读性** → **Mitigation**：强制玻璃内 `historyEditGlassTextColor`，与既有编辑 Sheet 一致。
- **[Trade-off]** 系统 `AlertDialog` 无障碍语义略变 → 保持 `Semantics` / `tooltip` 与按钮文案不变。

## Migration Plan

1. 实现 `app_glass_overlay.dart` + 单元手工验证（主页目录 picker、历史编辑、设置确认框）。
2. 迁移 `event_catalog_picker_sheet.dart`（用户首要目标）。
3. 迁移其余非玻璃 Sheet（reply、time wheel、trends 内联 picker）。
4. 将已玻璃 Sheet 改为共享入口（删除重复样板）。
5. 迁移全部 `AlertDialog` 至 `showGlassDialog`。
6. `flutter analyze` / 本地 `flutter run` 走查弹层列表。

**回滚**：恢复各文件旧 `showModalBottomSheet` / `showDialog` 调用即可，无数据迁移。

## Open Questions

- 目录 picker 是否在玻璃面板顶部保留 Material drag handle：建议 **否**，与历史编辑一致，用右上关闭或下滑 dismiss。
- `version_prompt` 下载进度是否允许非玻璃例外：**否**，统一玻璃以保持品牌一致。
