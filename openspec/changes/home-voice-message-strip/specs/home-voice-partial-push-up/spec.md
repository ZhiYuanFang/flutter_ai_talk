## MODIFIED Requirements

### Requirement: 转写条挤压历史区

The system SHALL render voice readable text in a dedicated strip between the history list and the bottom input panel, reducing the history Expanded height. 当语音模式存在可展示文案（非空 `_partial` 或非空 `_chatReply`）时，系统必须在**历史列表与底部固定输入区之间**展示**统一消息条**；该条高度必须占用纵向空间，使历史 `Expanded` 区域相应变矮。不得再单独为 partial 与 reply 维护两套顶栏组件。

#### Scenario: 按住说话 partial 增长

- **WHEN** 用户处于语音模式且 `_partial` 随识别更新变长
- **THEN** 消息条高度必须随内容增加（直至达到设计上限），且历史列表可视高度必须减小

#### Scenario: 回复到达后展示回复于消息条

- **WHEN** `sendCommand` 返回并写入 `_chatReply`
- **THEN** 消息条必须改为展示服务端回复（`_partial` 已清空），且不得隐藏消息条仅因「转写条」语义结束

### Requirement: 与底栏服务端回复分工

The system SHALL NOT show server reply or partial in the voice bottom caption slot; both SHALL use the upward message strip. 语音模式下，服务端回复与实时转写**均不得**在底栏 `HomeInputCaption` 展示；底栏仅保留语音球与相关手势/指示。文字输入模式仍可在底栏字幕展示回复。

#### Scenario: 有 partial 时底栏无字幕

- **WHEN** 消息条正在展示 `_partial`
- **THEN** 底栏不得显示 `HomeInputCaption` 或「聆听中…」

#### Scenario: 有回复时底栏无字幕

- **WHEN** 消息条正在展示 `_chatReply`
- **THEN** 底栏不得显示 `HomeInputCaption` 预览同一回复

## REMOVED Requirements

### Requirement: 回复到达后移除转写条

**Reason**: 回复改在统一消息条展示，不再「隐藏转写条、回到底栏回复」。

**Migration**: 由 `home-voice-message-strip` 中「有回复时显示回复」场景覆盖。
