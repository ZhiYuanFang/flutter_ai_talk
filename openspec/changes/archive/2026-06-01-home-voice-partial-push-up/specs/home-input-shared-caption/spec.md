## MODIFIED Requirements

### Requirement: 统一字幕框与覆盖规则

The home input area SHALL use a caption slot for server reply and listening placeholder; live partial transcription during voice capture SHALL use the upward push strip per `home-voice-partial-push-up` instead of the fixed 3-line bottom slot. 底栏固定字幕槽用于**服务端回复**（及无转写条时的「聆听中…」等）；语音**实时转写**在 `_partial` 非空且未被回复覆盖时，必须由**历史与底栏之间的转写条**展示，**不得**占用底栏 52px 三行省略槽。回复仍覆盖转写；长回复预览仍截断且可 BottomSheet 展开。

#### Scenario: 回复覆盖转写

- **WHEN** 松手或提交后 `sendCommand` 返回非空 `reply`
- **THEN** 转写条必须隐藏，底栏字幕框必须显示服务端回复

#### Scenario: 新一轮按住清空回复预览

- **WHEN** 用户开始新一轮按住说话
- **THEN** 必须清空上一轮服务端回复；转写条随新的 `_partial` 更新

#### Scenario: 聆听中 partial 不在底栏三行槽

- **WHEN** 用户按住说话且 `_partial` 非空
- **THEN** 底栏固定字幕槽不得用 3 行省略展示该 partial（由转写条负责）
