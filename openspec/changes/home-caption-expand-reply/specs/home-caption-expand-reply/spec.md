## ADDED Requirements

### Requirement: 仅服务端回复可展开

The system MUST allow expanding full text via bottom sheet only when the caption shows the server command reply (`_chatReply`), not partial transcription or listening placeholder. 系统必须仅在字幕框展示**服务端回复**（`sendCommand` 返回的 `_chatReply`）时提供展开能力；展示转写预览（`_partial`）或「聆听中…」时**不得**提供展开入口。

#### Scenario: 服务端长回复可点击展开

- **WHEN** 字幕框当前文案为服务端回复且该文案在 3 行预览内被截断
- **THEN** 用户点击字幕区域必须打开底部抽屉并显示完整回复全文

#### Scenario: 转写预览不可展开

- **WHEN** 字幕框当前文案为语音转写 partial 且文本被截断
- **THEN** 系统不得提供点击展开或底部抽屉

### Requirement: 底部抽屉展示全文

The system SHALL display the full server reply in a modal bottom sheet with scrollable content. 展开时必须使用**底部抽屉**（`BottomSheet` / `showModalBottomSheet`）展示**完整**服务端回复；内容区域必须可垂直滚动以阅读超长文本。

#### Scenario: 抽屉内为完整回复

- **WHEN** 用户通过字幕触发展开
- **THEN** 抽屉内显示的文本必须与 `_chatReply` 完整内容一致（无截断）

#### Scenario: 可关闭抽屉

- **WHEN** 用户向下拖动关闭手柄或点击遮罩关闭
- **THEN** 抽屉必须关闭并返回主页，字幕框仍保持 3 行预览

### Requirement: 未截断无需展开

The system MUST NOT show expand affordance when the reply fits within the caption preview. 当服务端回复未超出字幕框 3 行预览高度时，系统**不得**显示「可展开」点击态或强制打开抽屉。

#### Scenario: 短回复无点击展开

- **WHEN** 服务端回复较短且未触发 ellipsis 截断
- **THEN** 字幕区域不得响应展开点击（或根本不注册点击）

### Requirement: 不干扰按住说话

The caption expand interaction MUST NOT block voice hold, slide-to-cancel, or text input. 字幕展开交互不得破坏底部按住说话、滑出取消及文字输入；字幕可点击层须在手势上与语音圆按住区分（字幕置于可点击层，全屏按住 Listener 不得吞掉字幕点击）。

#### Scenario: 点击字幕不开始录音

- **WHEN** 用户在服务端回复字幕上点击以展开（非语音圆区域）
- **THEN** 系统不得因此开始一次新的按住录音会话
