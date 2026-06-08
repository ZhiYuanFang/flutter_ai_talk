## ADDED Requirements

### Requirement: Managed keyboard text field SHALL support hidden editing mode

The reusable `ManagedKeyboardTextField` MUST support a hidden visibility mode where the widget participates in the focus tree but is not visibly rendered as an inline editor on the hosting page. Hidden mode MUST still attach to `keyboardInputBridgeController` on focus and synchronize draft text normally.

`ManagedKeyboardTextField` 必须支持隐藏编辑模式：组件参与 focus 树但不在页面上以 inline 编辑器可见形式渲染；聚焦时仍须正常 attach 桥接并同步草稿。

#### Scenario: 隐藏模式聚焦 attach
- **WHEN** 宿主页面以 hidden 模式放置 `ManagedKeyboardTextField` 并调用 `requestFocus()`
- **THEN** 组件 SHALL 调用 `keyboardInputBridgeController.attach` 且键盘顶部确认条 SHALL 出现
- **AND** 页面上 SHALL NOT 将资料头部 swap 为可见 TextField

#### Scenario: 隐藏模式仍接收键盘输入
- **WHEN** hidden 模式字段聚焦且系统键盘可见
- **THEN** 用户键盘输入 SHALL 更新 controller 与确认条 draft，与 visible 模式一致

### Requirement: Managed keyboard text field SHALL expose blur-without-confirm callback

The component MUST accept an optional `onBlurWithoutConfirm` callback invoked when focus is lost without the user pressing the confirm bar「确定」, after the bridge applies the scene blur policy (discard or soft-sync).

组件必须提供可选 `onBlurWithoutConfirm` 回调；在用户未点「确定」而失焦、且桥接层完成 scene blur 策略后调用。

#### Scenario: 资料编辑失焦回调
- **WHEN** hidden 模式昵称字段失焦且 blur 策略为 discard restore
- **THEN** 桥接层 SHALL 恢复快照后调用 `onBlurWithoutConfirm`
- **AND** 宿主页面 SHALL 据此退出 editing UI 态并恢复静态只读展示

### Requirement: Managed keyboard text field SHALL declare blur policy per scene

When attaching via `ManagedKeyboardTextField`, the component MUST pass the appropriate blur-without-confirm policy to the bridge based on `scene`: `ucg.profile.nickname` and `ucg.profile.bio` MUST use discard-restore; `ucg.chat`, `ucg.post.comment`, and `ucg.compose.body` MUST use soft-sync; other scenes MUST use the legacy default detach behavior.

组件 attach 时必须按 `scene` 向桥接层声明 blur 策略：资料昵称/简介为 discard-restore；聊天/评论/发布正文为 soft-sync；其他场景保持 legacy 默认 detach。

#### Scenario: 发布正文声明 soft-sync
- **WHEN** `ManagedKeyboardTextField` 以 `scene: ucg.compose.body` attach
- **THEN** 失焦未确定时桥接层 SHALL 执行 soft-sync 而非 discard
- **AND** SHALL NOT 在 detach 路径触发本地草稿文件写入

## MODIFIED Requirements

### Requirement: Managed keyboard text field SHALL encapsulate bridge attach lifecycle

The client SHALL provide a reusable `ManagedKeyboardTextField` (or equivalent named widget) that wraps a standard `TextField` and automatically manages `keyboardInputBridgeController` attach, detach, and `updateDraft` synchronization when the field gains or loses focus. Detach MUST apply the scene-configured blur-without-confirm policy before clearing the binding.

客户端必须提供可复用的受管控文本输入组件，在聚焦时自动 attach、失焦时 detach 并同步 `updateDraft`；detach 时必须先执行 scene 配置的 blur-without-confirm 策略再清除 binding。

#### Scenario: 聚焦自动 attach
- **WHEN** 用户使用 `ManagedKeyboardTextField` 并点击输入框触发聚焦
- **THEN** 组件 SHALL 调用 `keyboardInputBridgeController.attach` 并传入 `controller`、`focusNode`、`hint`、`scene` 与 `onConfirm`

#### Scenario: 失焦自动 detach
- **WHEN** 该输入框失去焦点或父路由切换导致焦点清理
- **THEN** 组件 SHALL 按 scene blur 策略处理 draft 后调用 `keyboardInputBridgeController.detach`
- **AND** SHALL NOT 泄漏 binding

#### Scenario: 输入同步到确认条
- **WHEN** 用户在受管控输入框中输入文字且键盘或表情面板编辑态有效
- **THEN** 键盘顶部确认条 SHALL 通过 `updateDraft` 展示当前输入镜像（密码场景脱敏规则不变）
