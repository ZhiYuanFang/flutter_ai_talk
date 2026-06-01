## ADDED Requirements

### Requirement: 语音统一消息条

The system SHALL show voice-mode readable text (partial transcription and server reply) in one strip between history and the bottom panel, with reply over partial. 语音模式下，系统必须在历史列表与底栏 Divider 之间使用**唯一**消息条展示可读文案；优先级必须为：非空 `_chatReply` → 非空 `_partial` → 按住且无 partial 时显示「聆听中…」→ 否则不显示消息条。

#### Scenario: 有 partial 时显示转写

- **WHEN** 用户处于语音模式且 `_partial` 非空且 `_chatReply` 为空
- **THEN** 消息条必须展示 `_partial` 并随识别更新

#### Scenario: 有回复时显示回复

- **WHEN** 用户处于语音模式且 `_chatReply` 非空
- **THEN** 消息条必须展示服务端回复，且不得同时展示 `_partial`

#### Scenario: 按住尚无转写时显示聆听中

- **WHEN** 用户处于语音模式且正在按住（`_listening`）且 `_partial` 与 `_chatReply` 均为空
- **THEN** 消息条必须显示「聆听中…」，且底栏不得显示该文案

#### Scenario: 空闲时不显示条

- **WHEN** 用户处于语音模式且未按住且 `_partial` 与 `_chatReply` 均为空
- **THEN** 系统不得显示消息条

### Requirement: 语音底栏固定语音球

The voice bottom panel MUST NOT include a caption slot; the voice orb vertical position SHALL remain stable. 语音模式底栏约 220px 区域内**不得**插入 `HomeInputCaption` 或等价固定高度字幕槽；语音球必须在按住、partial 出现、回复到达全过程中保持同一垂直布局位置。

#### Scenario: 按住开始无球位移

- **WHEN** 用户从空闲状态按下语音区域开始采集
- **THEN** 底栏不得因新增字幕区域而改变语音球中心相对底栏的位置

#### Scenario: 回复到达无球位移

- **WHEN** 服务端回复写入且消息条切换为展示回复
- **THEN** 底栏语音球位置必须与回复到达前一致

### Requirement: 消息条高度与滚动

The message strip MUST support multi-line content with a maximum height cap and scrolling, consistent with partial push-up behavior. 消息条必须多行展示文案；最大高度不得超过屏高约定比例（如 30%）；超出必须可垂直滚动阅读全文。

#### Scenario: 超长 partial 可滚动

- **WHEN** `_partial` 内容高度超过消息条上限
- **THEN** 用户必须能在消息条内滚动查看完整转写

#### Scenario: 超长回复可滚动

- **WHEN** `_chatReply` 内容高度超过消息条上限
- **THEN** 用户必须能在消息条内滚动查看完整回复

### Requirement: 语音回复可展开全文

The system MUST allow opening the full server reply in a bottom sheet from the voice message strip when content exceeds the strip preview. 语音模式下，当消息条展示服务端回复且预览不足以阅读全文时，用户必须能通过点击消息条打开底部抽屉查看完整 `_chatReply`（复用既有 BottomSheet 实现）。

#### Scenario: 长回复点击展开

- **WHEN** 消息条展示服务端回复且系统判定需展开（如 strip 内存在可滚动溢出）
- **THEN** 用户点击消息条必须打开底部抽屉并显示完整回复

#### Scenario: partial 不可展开

- **WHEN** 消息条仅展示 `_partial`
- **THEN** 系统不得因点击消息条打开回复全文抽屉

### Requirement: 挤压历史区

The message strip SHALL reduce the Expanded history height when visible. 消息条可见时必须占用历史区下方的纵向空间，使历史 `Expanded` 可视高度相应减小。

#### Scenario: 消息条增高挤压历史

- **WHEN** 消息条文案变长导致条高度增加（直至上限）
- **THEN** 历史列表可视区域高度必须减小
