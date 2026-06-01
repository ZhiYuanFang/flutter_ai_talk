## 1. 统一轻提示组件

- [x] 1.1 新建 `app/lib/ui/widgets/app_toast.dart`：`AppToastTone`（info/success/error）、`showAppToast(message, {tone})`
- [x] 1.2 实现顶部 floating SnackBar：透明底、圆角雾面（~10% alpha）、`margin` 顶安全区 +12px、水平居中
- [x] 1.3 时长：info/success 1000ms，error 2000ms；展示前 `clearSnackBars()`

## 2. 总线接入

- [x] 2.1 扩展 `toast_bus.dart`（或等价）：支持 tone；错误 helper 默认 error
- [x] 2.2 `app.dart`：`apiToastProvider` listen 改为 `showAppToast`，不再裸 `SnackBar`
- [x] 2.3 `remote_feed_repository` / `remote_trends_repository` / `authorized_api_client` 等错误路径使用 error tone

## 3. 页面迁移

- [x] 3.1 `home_screen.dart`：语音相关 SnackBar → `showAppToast`（错误 2s）
- [x] 3.2 `history_detail_screen.dart`：校验/已保存/已删除 → 对应 tone
- [x] 3.3 `baby_profile_editor.dart`、`version_prompt.dart`：短 SnackBar 迁移
- [x] 3.4 `login_screen` / `baby_bind_screen` / `wechat_oauth_callback`：经 provider 的已自动覆盖；确认无遗漏底部 SnackBar

## 4. 验证

- [x] 4.1 手工：已记录（1s 雾面顶中）、API 错误（2s）、连点顶替
- [x] 4.2 夜空/浅色主题可读性
- [x] 4.3 `flutter analyze`  touched files + `openspec validate app-toast-top-hint`
