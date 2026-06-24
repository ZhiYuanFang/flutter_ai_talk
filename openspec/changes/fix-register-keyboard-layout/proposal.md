## Why

在 Android 14（vivo 等机型）上，注册页聚焦「确认密码」并弹出系统键盘后，页面顶起过程中出现卡死甚至进程被杀；同一套 `keyboard_lift` 逻辑在登录页（两字段、表单贴底）工作正常。根因是注册页采用顶对齐 Column，第三个输入框下方仍有按钮与协议文案，导致键盘 inset 与滚动顶起形成反馈环。需用最小改动（方案 A）将注册页主表单布局对齐登录页贴底策略，恢复稳定输入体验。

## What Changes

- 注册页 `SingleChildScrollView` 内主 `Column` 改为与登录页一致的 `MainAxisAlignment.end` 贴底布局。
- 返回按钮改为浮于内容区左上角（`Stack`），避免占用顶对齐表单垂直空间。
- 保持现有 `keyboard_lift`、`resizeToAvoidBottomInset: false`、三字段校验与视觉组件复用不变。
- **不改动** 全局 `keyboard_lift.dart` 重试逻辑（留作后续方案 B）。
- **不改动** 登录页、改密页及其它 auth 页面。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `account-registration`：补充注册页表单贴底布局与键盘聚焦时输入可达性要求，与登录页布局策略对齐。

## Impact

- **Flutter**：`app/lib/ui/register_screen.dart`（布局结构调整）。
- **测试**：现有 `app/test/registration_flow_test.dart` 应仍通过（finder 基于文案，不受布局对齐影响）；需在 Android 14 真机手工验证确认密码输入。
- **基线**：引用 `v2.0.2` 中 `account-registration` 能力并做 delta 扩展。
