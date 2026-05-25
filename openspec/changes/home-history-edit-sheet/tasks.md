## 1. 共享 Bottom Sheet 布局

- [x] 1.1 新增 `AppAdaptiveBottomSheet`（或等价）：`maxHeight = 2/3 屏`、`mainAxisSize: min`、溢出 `SingleChildScrollView`、`viewInsets`/safe area
- [x] 1.2 迁移 `event_catalog_picker_sheet`：去掉固定 `SizedBox(height: 2/3)`，改用共享布局
- [x] 1.3 迁移 `home_number_event_sheet` 套用共享 max 2/3 约束
- [x] 1.4 迁移 `home_reply_bottom_sheet`：整体 max 2/3，内容少时自适应

## 2. 用量滚轮与时分滚轮组件

- [x] 2.1 从 `home_number_event_sheet` 提取 `_numberPickerValues` 与 picker 常量为共享模块（如 `home_event_number_picker.dart`）
- [x] 2.2 新增 `HomeHistoryTimeWheel`（双列 Cupertino 时/分），支持锚定日期合成 `DateTime`
- [x] 2.3 更新 `home_number_event_sheet` 引用共享用量滚轮模块

## 3. 历史编辑 Sheet

- [x] 3.1 新增 `showHomeHistoryEditSheet` + 状态组件：EventNameHeader、只读日期、字段矩阵（eventNumber 0/1/>1）
- [x] 3.2 实现 pending 只读态（禁用滚轮/输入，隐藏保存/删除/停止，可选「同步中」提示）
- [x] 3.3 平移 `HistoryDetailScreen._save` 校验与 `updateHistoryRecord` 调用；成功 `replaceRecord` + Toast
- [x] 3.4 实现 Sheet 内删除（确认对话框 → `deleteHistoryRecord` → `removeRecord`）
- [x] 3.5 实现 Sheet 内停止计时（复用 `_stopActiveTimer` 语义，非 pending）
- [x] 3.6 实现 dirty dismiss 确认（PopScope / `barrierDismissible` 策略）

## 4. 主页接入与清理

- [x] 4.1 `home_screen._openHistory` 改为弹出编辑 Sheet（保留远程门禁）
- [x] 4.2 删除 `history_detail_screen.dart`
- [x] 4.3 移除 `app_router.dart` 中 `/history/:recordId` 路由与 import
- [x] 4.4 更新 `app/README.md` 主页历史交互描述
- [x] 4.5 `flutter analyze` 相关文件；手工验证：编辑/删除/停止/pending 只读/各 Sheet 高度
