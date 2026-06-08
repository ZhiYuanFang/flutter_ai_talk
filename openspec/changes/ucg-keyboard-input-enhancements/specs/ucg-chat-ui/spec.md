## ADDED Requirements

### Requirement: Chat input SHALL support emoji and newline via confirm bar

The UCG chat message input (`scene: ucg.chat`) MUST support Unicode emoji insertion and newline insertion exclusively through the keyboard-top confirm bar workflow (emoji toggle accessory and long-press draft「换行」menu). The chat input dock MUST NOT expose separate emoji or newline controls.

UCG 聊天消息输入必须仅通过键盘顶部确认条支持 emoji 插入与换行（accessory 切换与长按草稿菜单）；聊天输入 dock 不得单独提供 emoji 或换行控件。

#### Scenario: 聊天插入 emoji
- **WHEN** 用户在聊天页聚焦消息输入并通过确认条表情面板插入 emoji
- **THEN** 消息输入 controller 与确认条 draft SHALL 含该 emoji
- **AND** 用户点击「确定」 SHALL 等同现有发送逻辑

#### Scenario: 聊天长按换行
- **WHEN** 用户在 `ucg.chat` 场景长按确认条草稿并选择「换行」
- **THEN** 系统 SHALL 在消息输入当前选区插入换行符

### Requirement: Chat input blur without confirm SHALL soft-sync draft

When the chat message input loses focus without the user pressing confirm bar「确定」, the client MUST write the current bridge `draftText` back to the visible message input controller and MUST NOT send the message or invoke chat send `onConfirm`.

聊天消息输入在未点「确定」而失焦时，必须将 draft 软同步回可见输入 controller，且不得发送消息或调用发送 `onConfirm`。

#### Scenario: 聊天失焦保留输入内容
- **WHEN** 用户在聊天页输入消息但未点「确定」即点击聊天列表其他区域导致失焦
- **THEN** 消息输入框 SHALL 仍显示失焦前的 draft 文本
- **AND** SHALL NOT 触发消息发送

## MODIFIED Requirements

### Requirement: Chat input dock SHALL use minimal flat styling and keyboard bridge

The 1:1 chat screen input area MUST use a flat `UcgInputDock` (no glass card wrapper, no gradient send button) and MUST wire the message `TextField` through `ManagedKeyboardTextField` or equivalent `keyboardInputBridgeController` attach pattern. `onConfirm` SHALL map to send message. The dock MUST NOT include emoji toggle buttons; emoji entry SHALL be via confirm bar only.

聊天页输入区必须使用扁平输入条，消息输入必须接入键盘顶部确认条；点「确定」等同发送。dock 不得含 emoji 按钮；emoji 仅经确认条 accessory 进入。

#### Scenario: 聊天输入弹出确认条
- **WHEN** 已登录用户在聊天页点击消息输入框并唤起键盘
- **THEN** 键盘顶部 SHALL 显示确认条（含 UCG emoji accessory），主体聊天列表 SHALL NOT 整体上移

#### Scenario: 确定发送消息
- **WHEN** 用户在聊天场景键盘确认条点击「确定」
- **THEN** App SHALL 回填输入内容并执行发送逻辑（与发送按钮等价）
