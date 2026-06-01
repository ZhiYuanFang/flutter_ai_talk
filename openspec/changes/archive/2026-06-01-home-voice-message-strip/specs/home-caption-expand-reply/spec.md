## MODIFIED Requirements

### Requirement: 仅服务端回复可展开

The system MUST allow expanding full text via bottom sheet only for server command reply (`_chatReply`), from the text caption or the voice message strip as appropriate. 系统必须仅在展示**服务端回复**时提供展开能力：文字模式为底栏字幕框；语音模式为历史上方消息条。展示 `_partial` 或「聆听中…」时**不得**提供展开入口。

#### Scenario: 语音模式长回复在消息条展开

- **WHEN** 语音模式消息条展示服务端回复且预览不足以阅读全文
- **THEN** 用户点击消息条必须打开底部抽屉并显示完整回复全文

#### Scenario: 文字模式长回复在字幕展开

- **WHEN** 文字模式字幕框展示服务端回复且该文案在 3 行预览内被截断
- **THEN** 用户点击字幕区域必须打开底部抽屉并显示完整回复全文

#### Scenario: 转写预览不可展开

- **WHEN** 消息条或字幕框当前文案为语音转写 partial
- **THEN** 系统不得提供点击展开或底部抽屉

### Requirement: 不干扰按住说话

The expand interaction MUST NOT block voice hold, slide-to-cancel, or text input. 展开交互不得破坏底部按住说话、滑出取消及文字输入。语音模式下展开入口仅位于消息条（不在底栏 220px 全屏按住 Listener 区域内）。

#### Scenario: 点击消息条不开始录音

- **WHEN** 用户在语音模式消息条上点击以展开回复
- **THEN** 系统不得因此开始一次新的按住录音会话
