## Why

注册页（及同模式的登录、改密、绑定页）在聚焦密码类输入框并弹出系统键盘时，会因 `build()` 内重复调度键盘顶起 + 滚动动画叠加 + 底部 padding 与 scroll 顶起互搏，触发「布局顶起循环」，在 Android 14 等 IME inset 动画环境下偶发 ANR、输入框未被顶起、界面卡死。基线 v2.1.0 已有 `account-registration` 中「注册页确认密码聚焦时 MUST 可稳定输入」Requirement，但当前实现未满足验收。

## What Changes

- 将 `scheduleInlineAuthScrollOnInset` 从 auth 页 `build()` 副作用中移出，改为仅在 `viewInsets` **实质变化**时通过 observer / listener 调度一次顶起。
- 为 `keyboard_lift.dart` 的 inline auth 顶起路径增加幂等 guard（in-flight 跳过、inset 变化阈值、取消重复 `animateTo`）。
- 精简 auth 页顶起触发链：聚焦时单次 postFrame 顶起 + 有限 retry，避免每帧 rebuild 叠加多层 callback。
- 统一 auth 贴底表单顶起策略：保留 `bottomInset` padding 与 scroll lift 的协调计算，避免两者在同一帧反复修正。
- 注册页密码、确认密码及同模式页面（login / change-password / baby-bind）共享修复，行为与基线 Requirement 对齐。

## Capabilities

### New Capabilities

（无独立新 capability。）

### Modified Capabilities

- `account-registration`：扩展「稳定输入」Requirement 覆盖密码与确认密码字段；补充 auth 内联键盘顶起不得因 build 副作用循环调度的约束与验收场景。

## Impact

- `app/lib/ui/auth/auth_field_scroll.dart`：inset 监听与调度入口重构。
- `app/lib/ui/widgets/keyboard_lift.dart`：顶起幂等 guard、retry 精简。
- `app/lib/ui/register_screen.dart`、`login_screen.dart`、`change_password_screen.dart`、`baby_bind_screen.dart`：移除 build 内 `scheduleInlineAuthScrollOnInset` 调用，接入新 listener。
- 无 Android 原生改动、无新依赖、不涉及 WebSocket / 副作用 HTTP。
- 不涉及 `**/test/**` 新建（按 project.md 约定，真机手工验收为主）。
