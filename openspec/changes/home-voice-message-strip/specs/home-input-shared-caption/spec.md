## MODIFIED Requirements

### Requirement: 统一字幕框与覆盖规则

The home input area SHALL use the upward voice message strip for partial and server reply in voice mode; the bottom caption slot applies to text mode server reply only. 语音模式下，实时转写与服务端回复**均必须**由历史上方的**统一消息条**展示，底栏**不得**使用固定字幕槽展示聆听中、partial 或回复。文字模式下，服务端回复仍可在底栏 `HomeInputCaption` 展示；回复覆盖转写、新一轮按住清空回复等顺序规则不变。

#### Scenario: 回复覆盖转写

- **WHEN** 松手或提交后 `sendCommand` 返回非空 `reply`
- **THEN** 消息条必须改为展示服务端回复，且不得同时在底栏字幕框展示该回复

#### Scenario: 新一轮按住清空回复预览

- **WHEN** 用户开始新一轮按住说话
- **THEN** 必须清空上一轮服务端回复；消息条随新的 `_partial` 更新

#### Scenario: 语音聆听中在消息条无底栏字幕

- **WHEN** 用户按住说话但 `_partial` 仍为空
- **THEN** 消息条必须显示「聆听中…」；底栏不得显示「聆听中…」或任何字幕占位

#### Scenario: 文字模式底栏仍显示回复

- **WHEN** 用户处于文字输入且收到非空服务端回复
- **THEN** 回复必须仍在底栏统一字幕框组件中展示
