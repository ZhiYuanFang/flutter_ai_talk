# 验证记录（任务 3.1 / 3.2）

## 自动化验证

- `app/test/no_default_autofocus_test.dart`：验证文本确认弹窗默认不自动聚焦输入框。
- `app/test/keyboard_input_bridge_test.dart`：验证输入桥接确认回填与提交触发未回归。
- `app/test/registration_flow_test.dart`：验证注册流程核心行为未回归。

## 策略验证

- 路由层新增 `FocusCleanupNavigatorObserver`，在 push/pop/replace 后统一清理焦点与输入桥接状态，覆盖进入/返回当前页面场景。
- 已移除 `app_glass_overlay` 的 `autofocus: true`，消除弹窗展示即弹键盘的被动行为。
