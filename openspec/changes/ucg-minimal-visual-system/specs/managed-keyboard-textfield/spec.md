## ADDED Requirements

### Requirement: Managed keyboard text field SHALL encapsulate bridge attach lifecycle

The client SHALL provide a reusable `ManagedKeyboardTextField` (or equivalent named widget) that wraps a standard `TextField` and automatically manages `keyboardInputBridgeController` attach, detach, and `updateDraft` synchronization when the field gains or loses focus.

客户端必须提供可复用的受管控文本输入组件，在聚焦时自动 `attach` 键盘桥接、失焦时 `detach`，并在 `onChanged` 时调用 `updateDraft` 与确认条保持同步。

#### Scenario: 聚焦自动 attach
- **WHEN** 用户使用 `ManagedKeyboardTextField` 并点击输入框触发聚焦
- **THEN** 组件 SHALL 调用 `keyboardInputBridgeController.attach` 并传入 `controller`、`focusNode`、`hint`、`scene` 与 `onConfirm`

#### Scenario: 失焦自动 detach
- **WHEN** 该输入框失去焦点或父路由切换导致焦点清理
- **THEN** 组件 SHALL 调用 `keyboardInputBridgeController.detach` 且 SHALL NOT 泄漏绑定

#### Scenario: 输入同步到确认条
- **WHEN** 用户在受管控输入框中输入文字且键盘已弹出
- **THEN** 键盘顶部确认条 SHALL 通过 `updateDraft` 展示当前输入镜像（密码场景脱敏规则不变）

### Requirement: Managed keyboard text field SHALL expose scene submit mapping

The reusable component MUST accept an `onConfirm` callback that maps to the input context submit action (send message, post comment, save profile field, unfocus-only, etc.).

组件必须暴露 `onConfirm` 参数，映射到该输入场景的业务提交（发送、评论、保存、仅收起键盘等）。

#### Scenario: 确定触发场景提交
- **WHEN** 用户在键盘顶部确认条点击「确定」且绑定来自 `ManagedKeyboardTextField`
- **THEN** 系统 SHALL 将确认条文本回填至目标 `controller` 并执行该字段配置的 `onConfirm`
