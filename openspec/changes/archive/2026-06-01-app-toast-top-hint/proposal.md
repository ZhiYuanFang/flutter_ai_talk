## Why

当前应用内短时反馈统一走 Material 底部 `SnackBar`（实心条、默认约 4 秒），与主页底部输入区抢空间，且与「已记录」等高频轻提示不匹配。需要改为**屏幕中上方**、**圆角雾面**、**快速消失**的统一轻提示，提升可读性与操作连贯性。

## What Changes

- 新增全局 **`AppToast` / `showAppToast`**：顶部居中悬浮，圆角雾面背景（极低不透明度），纯文字为主。
- **时长**：成功/信息类 **1s**；错误类 **2s**。
- **集中出口**：`apiToastProvider` 监听改为调用统一轻提示（不再使用默认底部 SnackBar）。
- **迁移**：替换各页面直接 `ScaffoldMessenger.showSnackBar` 的短时文案（主页语音错误、详情校验、宝宝资料、版本提示等）。
- **不改动**：需用户确认或长文案的 `Dialog` / 版本弹窗（非 toast 范畴）。
- 现有 OpenSpec 中仅规定「Toast 文案与时机」的能力（如「已记录」）**保留文案要求**，展示形态改为本变更定义。

## Capabilities

### New Capabilities

- `app-transient-top-hint`: 全局顶部轻提示（位置、雾面样式、时长分档、队列/顶替、与主题色）。

### Modified Capabilities

（无独立 `openspec/specs/` 基线文件；相关 delta 写在变更内 `specs/` 下，供实现与回归引用。）

## Impact

- `app/lib/app.dart` — `apiToastProvider` 展示路径
- 新建 `app/lib/ui/widgets/app_toast.dart`（或 `app/lib/app_toast.dart`）
- `app/lib/providers/toast_bus.dart` — 可扩展 tone / 辅助方法
- `home_screen.dart`、`history_detail_screen.dart`、`baby_profile_editor.dart`、`version_prompt.dart` 等 SnackBar 调用点
- 可选：`remote_feed_repository` 等经 `apiToastProvider` 的调用方无需改语义，仅展示层变化
