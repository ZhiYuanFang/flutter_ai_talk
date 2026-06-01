# 输入入口盘点（任务 1.1）

## 页面输入

- `app/lib/ui/home_screen.dart`：`_webController`（文本命令输入）
- `app/lib/ui/login_screen.dart`：`_accountCtrl`、`_passwordCtrl`
- `app/lib/ui/register_screen.dart`：`_accountCtrl`、`_passwordCtrl`、`_confirmPasswordCtrl`
- `app/lib/ui/baby_bind_screen.dart`：`_deviceCtrl`、`_nicknameCtrl`
- `app/lib/ui/baby_profile_editor.dart`：`_nicknameCtrl`

## 弹层/对话框输入

- `app/lib/ui/settings_screen.dart`：单字段与双字段 `TextField`
- `app/lib/ui/home_history_edit_sheet.dart`：备注输入 `TextField`
- `app/lib/ui/home_number_event_sheet.dart`：备注输入 `TextField`
- `app/lib/ui/widgets/app_glass_overlay.dart`：文本确认输入 `TextField`

## 默认聚焦风险点

- `app/lib/ui/widgets/app_glass_overlay.dart` 之前存在 `autofocus: true`，会在弹窗出现时自动弹出键盘。
- 路由 push/pop 后可能出现焦点残留，导致返回当前界面时键盘被动弹出。
