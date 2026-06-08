## ADDED Requirements

### Requirement: Chat input dock SHALL use minimal flat styling and keyboard bridge

The 1:1 chat screen input area MUST use a flat `UcgInputDock` (no glass card wrapper, no gradient send button) and MUST wire the message `TextField` through `ManagedKeyboardTextField` or equivalent `keyboardInputBridgeController` attach pattern. `onConfirm` SHALL map to send message.

聊天页输入区必须使用扁平输入条（非玻璃 dock），且消息输入必须接入键盘顶部确认条；点「确定」等同发送消息。

#### Scenario: 聊天输入弹出确认条
- **WHEN** 已登录用户在聊天页点击消息输入框并唤起键盘
- **THEN** 键盘顶部 SHALL 显示确认条，主体聊天列表 SHALL NOT 整体上移

#### Scenario: 确定发送消息
- **WHEN** 用户在聊天场景键盘确认条点击「确定」
- **THEN** App SHALL 回填输入内容并执行发送逻辑（与发送按钮等价）

### Requirement: Conversation list rows SHALL use minimal surfaces

Conversation list items in 消息 Tab MUST NOT use glass card wrappers; they SHALL use flat list rows or light-surface dividers per `ucg-visual-system`.

消息列表会话行不得使用玻璃卡片包裹，应采用简约列表行或轻分割线样式。

#### Scenario: 消息列表无玻璃行卡
- **WHEN** 用户打开消息 Tab 浏览会话列表
- **THEN** 列表项 SHALL NOT 使用 `BackdropFilter` 玻璃行卡
