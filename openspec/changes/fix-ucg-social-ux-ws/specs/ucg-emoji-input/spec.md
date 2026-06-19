## ADDED Requirements

### Requirement: Chat emoji toggle SHALL open panel without prior keyboard focus

For scene `ucg.chat`, when the system keyboard is hidden and no binding exists yet, tapping the dock emoji toggle MUST attach the chat controller to `keyboardInputBridgeController`, MUST NOT show the system IME, and MUST display the inline emoji panel below the dock at `KeyboardOverlayMetrics.emojiPanelMinHeight` or greater.

`ucg.chat` 场景下，系统键盘未唤起且无 binding 时，点击 dock 表情按钮必须先 attach controller、不得弹出系统键盘，并在 dock 下方展示 emoji 面板（高度不小于预设最小值）。

#### Scenario: 无键盘点表情出面板

- **WHEN** 用户在聊天页未聚焦输入框且系统键盘未显示
- **THEN** 用户点击 dock 表情图标后 SHALL 在 dock 正下方展示 emoji 面板
- **AND** 系统键盘 SHALL 保持隐藏

### Requirement: Chat emoji mode SHALL dismiss panel on outside tap

For scene `ucg.chat` with inline emoji panel displayed (`KeyboardOverlayConfig` all false), tapping outside the keyboard-interaction exclude region MUST call `collapseInputChrome()` and MUST hide the emoji panel. `shouldSuppressOutsideDismiss` MUST NOT block dismiss solely because `_target == InputTarget.emoji` for page-inline composer scenes.

聊天 inline emoji 模式下，点击输入交互区外部必须收起 emoji 面板；`shouldSuppressOutsideDismiss` 不得仅因 emoji 模式而阻止外部 dismiss。

#### Scenario: 表情模式点消息列表收起

- **WHEN** 用户在聊天页处于 emoji 面板模式且点击消息列表空白区域
- **THEN** emoji 面板 SHALL 隐藏
- **AND** binding 草稿 SHALL 保留在 controller 中

#### Scenario: 表情模式点顶栏收起

- **WHEN** 用户在聊天页 emoji 面板展开时点击顶栏或返回区域（非输入 exclude 区）
- **THEN** emoji 面板 SHALL 收起
