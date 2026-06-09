## REMOVED Requirements

### Requirement: Chat input SHALL support emoji and newline via confirm bar

**Reason**: 聊天改为无全局浮层，emoji/换行在 dock Field 与 dock emoji 面板完成。

**Migration**: 见 ADDED「Chat dock SHALL host inline emoji panel」。

### Requirement: Chat input blur without confirm SHALL soft-sync draft

**Reason**: 聊天无浮层确定；文本始终由 dock controller 持有，无需 bridge soft-sync。

**Migration**: 失焦保留 controller 文本即可。

## MODIFIED Requirements

### Requirement: Chat input dock SHALL use minimal flat styling and keyboard bridge

The 1:1 chat screen input area MUST use flat `UcgInputDock` wired through `keyboardInputBridgeController` with all `KeyboardOverlayConfig` flags false. The dock MUST include an inline emoji toggle on the input row. `onSend` on the dock send button SHALL send the message. The global overlay MUST NOT appear for chat.

聊天 dock 必须扁平样式、bridge attach 且四 config false；行内 emoji；发送由 dock 按钮执行；不得展示全局浮层。

#### Scenario: 聊天无全局浮层
- **WHEN** 已登录用户在聊天页聚焦消息输入
- **THEN** 全局 `KeyboardInputConfirmBarOverlay` SHALL NOT 可见
- **AND** 消息输入 dock SHALL 保持可编辑

#### Scenario: dock 发送消息
- **WHEN** 用户点击 dock「发送」且消息非空
- **THEN** App SHALL 执行现有发送逻辑

## ADDED Requirements

### Requirement: Chat dock SHALL host inline emoji panel below input row

For `ucg.chat`, the client MUST render an emoji toggle on the dock row and an emoji panel directly below the dock with height approximately equal to the last recorded keyboard inset.

聊天必须在 dock 行展示 emoji 切换，并在 dock 正下方展示高度约等于键盘的 emoji 面板。

#### Scenario: emoji 面板在 dock 下方
- **WHEN** 用户在聊天页点击 dock emoji 切换
- **THEN** 系统 SHALL 收起系统软键盘
- **AND** SHALL 在 dock 正下方展示 emoji 面板
- **AND** binding SHALL 保持有效

#### Scenario: emoji 面板高度
- **WHEN** emoji 面板展开且 `lastKeyboardInset` 大于零
- **THEN** 面板高度 SHOULD 近似最近一次键盘 inset 高度

### Requirement: Chat media selection SHALL use top prefab strip before send

For `ucg.chat`, media picked via attach MUST appear in a prefabricated strip above the message list as pending attachments. The client MUST NOT send media until the user presses dock send.

聊天多媒体必须先出现在消息列表上方预制区，点发送后才发出。

#### Scenario: 选图后顶部预制
- **WHEN** 用户在聊天页通过 attach 选择图片或视频
- **THEN** UI SHALL 在消息列表上方展示可删除的缩略预制
- **AND** SHALL NOT 立即发送该媒体消息

#### Scenario: 发送携带预制媒体
- **WHEN** 用户点击 dock 发送且存在预制媒体或文本
- **THEN** App SHALL 按现有发送逻辑一并提交

### Requirement: Chat component lift SHALL anchor input dock region

When chat input is focused, component lift MUST anchor the dock region (including emoji panel when visible) above the keyboard.

聊天顶组件必须锚定 dock 区域（含 emoji 面板）。

#### Scenario: 键盘不遮挡 dock
- **WHEN** 用户在聊天页聚焦输入且系统键盘弹出
- **THEN** 消息输入 dock SHALL 完整可见且不被键盘遮挡

### Requirement: Chat message list SHALL sync scroll when input chrome resizes

When the chat message list viewport height changes because the input dock grows or shrinks (system keyboard inset, inline emoji panel, or dock bottom padding), the client MUST adjust list scroll so content remains readable.

When the user is scrolled near the latest messages (within a bottom threshold), the list MUST re-anchor to the latest message. When the user has scrolled up to read history, the list MUST compensate scroll offset by the viewport height delta so previously visible messages stay visible.

键盘/emoji 改变消息区可视高度时，消息列表必须同步滚动：贴底时跟到最新消息；看历史时按视口高度差补偿 offset，避免刚读到的消息被键盘挡住。

#### Scenario: 读历史时键盘弹出
- **WHEN** 用户向上滚动查看历史消息且聚焦输入框
- **AND** 系统键盘或 dock emoji 面板使消息列表可视高度减小
- **THEN** 消息列表 SHALL 增加 scroll offset（约等于可视高度减小量）
- **AND** 键盘弹出前可见的消息区域 SHOULD 仍保持可见

#### Scenario: 贴底时键盘弹出
- **WHEN** 用户已在最新消息附近（距底部不超过阈值）且聚焦输入框
- **AND** 输入 dock 因键盘或 emoji 面板变高
- **THEN** 消息列表 SHALL 滚动到底部以跟住最新消息
