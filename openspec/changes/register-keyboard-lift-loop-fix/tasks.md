## 1. 键盘顶起基础设施

- [x] 1.1 在 `keyboard_lift.dart` 为 inline auth 顶起增加 in-flight / inset 桶幂等 guard，精简 `allowInsetRetry` 为单次 delayed retry
- [x] 1.2 新增 `scheduleInlineAuthKeyboardLift`（或等效）仅一层 postFrame，供 focus listener 调用
- [x] 1.3 在 `auth_field_scroll.dart` 实现 `InlineAuthKeyboardLiftHost`（或 mixin + `WidgetsBindingObserver`），在 inset 实质变化时调度一次 `performKeyboardLift`

## 2. Auth 页接线

- [x] 2.1 `register_screen.dart`：移除 `LayoutBuilder.builder` 内 `scheduleInlineAuthScrollOnInset`，改用 `InlineAuthKeyboardLiftHost` 包裹 scroll 区域
- [x] 2.2 `login_screen.dart`：同上移除 build 副作用并接入 host
- [x] 2.3 `change_password_screen.dart`、`baby_bind_screen.dart`：同上移除 build 副作用并接入 host

## 3. 验收

- [ ] 3.1 真机验证注册页：直接点密码、直接点确认密码、账号→下一项→密码→下一项→确认密码，均可输入且无 ANR
- [ ] 3.2 真机验证登录页密码聚焦顶起正常，改密页两字段正常
- [ ] 3.3 确认键盘收起后贴底布局恢复，无异常 scroll offset 残留
